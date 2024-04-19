# lambda_api_sqs_pipes
1. Created a Azure DevOps pipeline to build the infrastructure thru HCL Terraform code to generate the AWS Lambda function which has AWS API Gateway as trigger and added Amazon SQS and Event Driven Pipes
2. Entire infra as a code will be build thru ADO Pipeline with no manual intervention
3. In ADO Pipeline, I have configured couple of pipelines used both methods : Self Hosted Agent(AWS Instance) and Microsoft Hosted agent to build this infra as code.

Resources Used: 
- Terraform 
- AWS API Gateway
- AWS EC2 Instance
- AWS Lambda
- AWS Cloudwatch Events
- AWS Event Driven Pipes
- AWS SQS Queues
- AWS IAM
- Azure DevOps Pipeline
- YAML
- GitHub

Sample screenshots: 
<img width="913" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/b8b99052-0944-481d-87b3-50df0adfba80">
<img width="923" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/ffbe33f2-e5e7-4f6d-be2f-b6196f8b8162">
<img width="922" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/cad031bc-225f-40f6-9d60-c1ac50a065cc">

