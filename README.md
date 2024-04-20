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

Flow: 

<img width="1882" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/c2f01846-d532-486e-822d-3d369bec23e5">

Sample screenshots: 
<img width="913" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/b8b99052-0944-481d-87b3-50df0adfba80">
<img width="923" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/ffbe33f2-e5e7-4f6d-be2f-b6196f8b8162">
<img width="920" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/5e6fd147-584c-4bba-8850-105c0824d6a1">
<img width="922" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/cad031bc-225f-40f6-9d60-c1ac50a065cc">
<img width="917" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/dd637a90-aa60-4a51-bb35-d861bd05e4f9">
<img width="920" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/7d5f2c20-d274-4118-b103-8736ad5d84bd">
<img width="920" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/74d77c8a-9cfe-4c24-a7cc-0395e1190720">
<img width="920" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/1ad0a8d4-bd99-413e-8149-46442209d021">
<img width="955" alt="image" src="https://github.com/srinivle/lambda_api_sqs_pipes/assets/50224645/1927305d-64d9-4d8f-a811-f2552b163b7f">



