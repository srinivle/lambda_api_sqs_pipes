# lambda_api_sqs_pipes
1. Created a Azure DevOps pipeline to build the infrastructure thru HCL Terraform code to generate the AWS Lambda function which has AWS API Gateway as trigger and added Amazon SQS and Event Driven Pipes
2. Entire infra as a code will be build thru ADO Pipeline with no manual intervention
3. In ADO Pipeline, I have configured couple of pipelines used both methods : Self Hosted Agent(AWS Instance) and Microsoft Hosted agent to build this infra as code.

