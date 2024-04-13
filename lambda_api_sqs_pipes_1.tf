terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0" //"4.50.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

# Variables
variable "myregion" { default = "us-east-1" }

variable "accountId" { default = "058264069674" }

# API Gateway Creation
resource "aws_api_gateway_rest_api" "api" {
  name = "myDemoApi"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" //for Lambda proxy integration
  uri                     = aws_lambda_function.sampleone.invoke_arn
}

//HTTP Method Integration Response for an API Gateway Resource

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
  depends_on  = [aws_api_gateway_integration.integration]
}

resource "aws_api_gateway_integration_response" "sampleinteg" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
  }

  depends_on = [aws_api_gateway_integration.integration]

}

//API Gateway REST Deployment

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource.id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}

# Invoke Lambda using API Gateway
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sampleone.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/*/*"

}

# Lambda Function Creation
resource "aws_lambda_function" "sampleone" {
  //filename      = "lambda.zip"
  function_name = "mylambda123"
  role          = aws_iam_role.role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.12"
  s3_bucket     = "sample88563"
  s3_key        = "sample.zip"
  //source_code_hash = filebase64sha256("lambda.zip")
}


resource "aws_lambda_function_url" "sampleone1" {
  depends_on         = [aws_lambda_function.sampleone]
  function_name      = aws_lambda_function.sampleone.function_name
  authorization_type = "NONE"
}
/*
resource "aws_lambda_function_url" "test_live" {
  depends_on = [ aws_lambda_function.sampleone, aws_lambda_function_url.sampleone1 ]
  function_name      = aws_lambda_function.sampleone.function_name
  //qualifier          = "my_alias"
  authorization_type = "AWS_IAM"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
)
*/
# IAM Creation for Lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "myDemoRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}




/*
//Creating SQS Resource
resource "aws_sqs_queue" "sample_queue" {
  depends_on                = [aws_sqs_queue.sample_queue_deadletterq]
  name                      = "sample-queue.fifo"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sample_queue_deadletterq.arn
    maxReceiveCount     = 4
  })

  sqs_managed_sse_enabled = true

  tags = {
    Environment = "dev"
  }
}
*/
/*SQS FIFO queue
resource "aws_sqs_queue" "sample_queue1" {
  name                        = "sample-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true

  depends_on = [ aws_sqs_queue.sample_queue ]
}*/


//SQS High-throughput FIFO queue
resource "aws_sqs_queue" "sample_queue2" {
  name                  = "sample-queue.fifo"
  fifo_queue            = true
  deduplication_scope   = "messageGroup"
  fifo_throughput_limit = "perMessageGroupId"
  //depends_on = [ aws_sqs_queue.sample_queue ] //aws_sqs_queue.sample_queue1 ]
}

//SQS Dead-letter queue
resource "aws_sqs_queue" "sample_queue3" {
  depends_on = [ aws_sqs_queue.sample_queue_deadletterq ]/*aws_sqs_queue.sample_queue, aws_sqs_queue.sample_queue2,*/
  name = "sample-queue3"
  sqs_managed_sse_enabled = true
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sample_queue_deadletterq.arn //aws_sqs_queue.sample_queue_deadletter.arn
    maxReceiveCount     = 60
  })
}

resource "aws_sqs_queue" "sample_queue_deadletterq" {
  name = "sample-queue-deadletter-queue"
}

resource "aws_sqs_queue_redrive_allow_policy" "sample_queue_redrive_allow_policy" {
  depends_on = [aws_sqs_queue.sample_queue3, aws_sqs_queue.sample_queue_deadletterq]
  queue_url  = aws_sqs_queue.sample_queue_deadletterq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.sample_queue3.arn]
  })
}

/*
//SQS Server-side encryption (SSE)
resource "aws_sqs_queue" "sample_queue4" {
  name                    = "sample-queue4"
  sqs_managed_sse_enabled = true

  depends_on = [ aws_sqs_queue.sample_queue, aws_sqs_queue.sample_queue2, aws_sqs_queue.sample_queue3 ]

}
*/


//Provides an EventBridge connection resource.
resource "aws_cloudwatch_event_connection" "example_pipes1" {
  name               = "example-connection"
  description        = "A connection description"
  authorization_type = "BASIC"

  auth_parameters {
    basic {
      username = "demouser"
      password = "Pass1234!"
    }
  }
}
//Provides an EventBridge event API Destination resource
resource "aws_cloudwatch_event_api_destination" "example_pipes2" {
  name                             = "example-api-destination"
  description                      = "An API Destination"
  invocation_endpoint              = aws_lambda_function_url.sampleone1.function_url
  http_method                      = "POST"
  invocation_rate_limit_per_second = 20
  connection_arn                   = aws_cloudwatch_event_connection.example_pipes1.arn

  depends_on = [aws_cloudwatch_event_connection.example_pipes1]
}

//Terraform resource for managing an AWS EventBridge Pipes Pipe
data "aws_caller_identity" "main" {}
resource "aws_iam_role" "example_pipes3" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "pipes.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.main.account_id
        }
      }
    }
  })
}


resource "aws_iam_role_policy" "source" {
  role = aws_iam_role.example_pipes3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
        ],
        Resource = [
          aws_sqs_queue.source.arn,
        ]
      },
    ]
  })
}
resource "aws_sqs_queue" "source" {}



resource "aws_iam_role_policy" "target" {
  role = aws_iam_role.example_pipes3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
        ],
        Resource = [
          aws_sqs_queue.target.arn,
        ]
      },
    ]
  })
}
resource "aws_sqs_queue" "target" {}


/*
resource "aws_pipes_pipe" "example_pipes4" {
  depends_on = [aws_iam_role_policy.source, aws_iam_role_policy.target]
  name       = "example-pipe"
  role_arn   = aws_iam_role.example_pipes3.arn
  source     = aws_sqs_queue.source.arn
  target     = aws_sqs_queue.target.arn
}
*/


//Enrichment Usage
resource "aws_pipes_pipe" "example_pipes" {
  depends_on = [aws_iam_role_policy.source, aws_iam_role_policy.target, aws_cloudwatch_event_api_destination.example_pipes2, aws_cloudwatch_event_connection.example_pipes1]  
  name     = "example-pipe"
  role_arn = aws_iam_role.example_pipes3.arn
  source   = aws_sqs_queue.source.arn
  target   = aws_sqs_queue.target.arn

  enrichment = aws_cloudwatch_event_api_destination.example_pipes2.arn

  enrichment_parameters {
    http_parameters {
      path_parameter_values = [aws_api_gateway_rest_api.api.id]

      header_parameters = {
        "example-header"        = "example-value"
        "second-example-header" = "second-example-value"
      }

      query_string_parameters = {
        "example-query-string"        = "example-value"
        "second-example-query-string" = "second-example-value"
      }
    }
  }
  //depends_on = [ aws_pipes_pipe.example_pipes4 ]

  source_parameters {
    sqs_queue_parameters {
      batch_size                         = 1
      maximum_batching_window_in_seconds = 2
    }

    filter_criteria {
      filter {
        pattern = jsonencode({
          source = ["event-source"]
        })
      }
    }

  }

}


/*
//Filter Usage
resource "aws_pipes_pipe" "example_pipes6" {
  name     = "example-pipe6"
  role_arn = aws_iam_role.example_pipes3.arn
  source   = aws_sqs_queue.source.arn
  target   = aws_sqs_queue.target.arn

  source_parameters {
    filter_criteria {
      filter {
        pattern = jsonencode({
          source = ["event-source"]
        })
      }
    }
  }
  depends_on = [ aws_pipes_pipe.example_pipes4, aws_pipes_pipe.example_pipes5 ]
}
*/

/*
//SQS Source and Target Configuration Usage
resource "aws_pipes_pipe" "example_pipes7" {
  name     = "example-pipe7"
  role_arn = aws_iam_role.example_pipes3.arn
  source   = aws_sqs_queue.source.arn
  target   = aws_sqs_queue.target.arn

  source_parameters {
    sqs_queue_parameters {
      batch_size                         = 1
      maximum_batching_window_in_seconds = 2
    }
  }

  target_parameters {
    sqs_queue {
      message_deduplication_id = "example-dedupe"
      message_group_id         = "example-group"
    }
  }

 depends_on = [ aws_pipes_pipe.example_pipes4, aws_pipes_pipe.example_pipes5, aws_pipes_pipe.example_pipes6 ]
}

*/

/*
//Output Values
output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "api_gateway_endpoint" {
  value = aws_api_gateway_rest_api.api.disable_execute_api_endpoint
}

output "api_gateway_deploy" {
  value = aws_api_gateway_deployment.deploy.id
}

output "lambda_function01" {
  value = aws_lambda_function.sampleone.id
}

output "lambda_function02" {
  value = aws_lambda_function.sampleone.image_uri
}


output "api_gateway_resource" {
  value = aws_api_gateway_resource.resource.id
}

output "api_gateway_resourcepath" {
  value = aws_api_gateway_resource.resource.path
}

output "api_gateway_resourcerestapi" {
  value = aws_api_gateway_resource.resource.rest_api_id
}

output "cloudwatch_api_destination" {
  value = aws_cloudwatch_event_api_destination.example_pipes2.id
}

output "lambda_function_url" {
  value = aws_lambda_function_url.sampleone1.function_url
}

output "lambda_function_urlid" {
  value = aws_lambda_function_url.sampleone1.url_id
}

output "sqs_redrive_allowpolicy" {
  value = aws_sqs_queue_redrive_allow_policy.sample_queue_redrive_allow_policy.id
}

output "sqs_redrive_allowpolicyqurl" {
  value = aws_sqs_queue_redrive_allow_policy.sample_queue_redrive_allow_policy.queue_url
}

output "lambda_perm" {
  value = aws_lambda_permission.apigw_lambda.id
}

output "pipe4id" {
  value = aws_pipes_pipe.example_pipes4.id
}

output "pipe5id" {
  value = aws_pipes_pipe.example_pipes5.id
}

output "pipe6id" {
  value = aws_pipes_pipe.example_pipes6.id
}

output "pipe7id1" {
  value = aws_pipes_pipe.example_pipes7.id
}

output "pipe7id2" {
  value = aws_pipes_pipe.example_pipes7.source_parameters
}

output "pipe7id3" {
  value = aws_pipes_pipe.example_pipes7.source
}

output "pipe7id4" {
  value = aws_pipes_pipe.example_pipes7.target
}

output "pipe7id5" {
  value = aws_pipes_pipe.example_pipes7.enrichment
}

output "aws_sample_q1" {
  value = aws_sqs_queue.sample_queue.id
}

output "aws_sample_q2" {
  value = aws_sqs_queue.sample_queue.url
}

output "aws_sample_q21" {
  value = aws_sqs_queue.sample_queue2.id
}

output "aws_sample_q22" {
  value = aws_sqs_queue.sample_queue2.url
}

output "aws_sample_q31" {
  value = aws_sqs_queue.sample_queue3.id
}

output "aws_sample_q32" {
  value = aws_sqs_queue.sample_queue3.url
}

output "aws_sample_q41" {
  value = aws_sqs_queue.sample_queue4.id
}

output "aws_sample_q42" {
  value = aws_sqs_queue.sample_queue4.url
}

output "aws_sample_q80" {
  value = aws_sqs_queue.sample_queue_deadletter.id
}

output "aws_sample_q81" {
  value = aws_sqs_queue.sample_queue_deadletter.url
}

output "aws_sample_q82" {
  value = aws_sqs_queue.sample_queue_deadletter.redrive_policy
}

output "aws_sample_q83" {
  value = aws_sqs_queue.sample_queue_deadletter.redrive_allow_policy
}

output "aws_sample_q84" {
  value = aws_sqs_queue.sample_queue_deadletter.fifo_throughput_limit
}
*/
