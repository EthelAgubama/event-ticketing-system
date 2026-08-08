# Event Registration & Ticketing System

A serverless REST API and web app for registering people to events, built on AWS. It replaces the old Microsoft Forms plus Excel workflow with something that scales on its own and does not need manual tracking.

**Live site:** http://event-ticketing-frontend-871049984358.s3-website-us-east-1.amazonaws.com
**Live API:** https://yibiebjui9.execute-api.us-east-1.amazonaws.com/dev/events

![Event Registration and Ticketing System](docs/screenshot.png)

Built as a capstone project for the Azubi Africa AWS Cloud Infrastructure Programme.

---

## What this does

Organizers can list events, and participants can register for them through a simple web form. Every part of the system, from the database to the API to the hosting, is built with Terraform, so the whole thing can be torn down and rebuilt from code. Deployments happen automatically through GitHub Actions whenever code is pushed to main.

---

## Architecture

GitHub Repository leads to GitHub Actions CI/CD, which runs Terraform Apply.

That deploys into AWS Cloud:

API Gateway (REST) with four routes:
- GET /events
- GET /events/eventId
- POST /events/eventId/register
- GET /events/eventId/registrations

Those routes call Lambda Functions written in Python 3.12:
- list_events
- get_event
- register
- list_registrations

The Lambda functions read and write to DynamoDB:
- Events table
- Registrations table

Supporting services:
- Amazon SES sends confirmation emails
- CloudWatch handles logging and alarms
- SNS sends admin alert notifications
- AWS Budgets handles cost monitoring
- S3 hosts the frontend

---

## Tech stack

| Layer | Technology |
|---|---|
| Infrastructure as code | Terraform |
| Compute | AWS Lambda (Python 3.12) |
| API | Amazon API Gateway (REST) |
| Database | Amazon DynamoDB |
| Frontend hosting | Amazon S3 (static website) |
| Email | Amazon SES |
| Monitoring | Amazon CloudWatch and SNS |
| Cost control | AWS Budgets |
| CI/CD | GitHub Actions |
| Frontend | HTML, CSS, vanilla JavaScript |

---

## Repository structure

event-ticketing-system contains:
- terraform folder with main.tf, variables.tf, outputs.tf, dynamodb.tf, iam.tf, lambda.tf, api_gateway.tf, frontend.tf, budget.tf, and monitoring.tf
- lambda folder with list_events, get_event, register, and list_registrations subfolders
- frontend folder with index.html
- docs folder with screenshot.png
- .github/workflows folder with deploy.yml
- README.md

---

## API endpoints

| Method | Path | What it does |
|---|---|---|
| GET | /events | List all events |
| GET | /events/eventId | Get one event's details |
| POST | /events/eventId/register | Register a participant (send name and email) |
| GET | /events/eventId/registrations | List everyone registered for an event |

### Example: registering for an event

```bash
curl -X POST "https://yibiebjui9.execute-api.us-east-1.amazonaws.com/dev/events/evt001/register" -H "Content-Type: application/json" -d "{\"name\": \"Jane Doe\", \"email\": \"jane@example.com\"}"
```

The register endpoint checks a few things before it lets someone in:
- The event has to actually exist, or it returns a 404
- The event cannot be full, or it returns a 409
- The same email cannot register twice for the same event, or it returns a 409
- If everything checks out, it writes the registration, bumps up the event's registered count, and sends a confirmation email through SES

---

## Data model

**Events table**

| Attribute | Type | Notes |
|---|---|---|
| eventId (partition key) | String | |
| eventName | String | |
| eventDate | String | ISO date |
| capacity | Number | |
| registeredCount | Number | Goes up automatically when someone registers |
| status | String | Available, Limited, or Full |

**Registrations table**

| Attribute | Type | Notes |
|---|---|---|
| eventId (partition key) | String | |
| email (sort key) | String | Combined with eventId, stops duplicate registrations |
| name | String | |
| timestamp | String | ISO 8601, UTC |
| status | String | |

---

## CI/CD pipeline

Every push to main kicks off a GitHub Actions workflow that:

1. Checks out the code
2. Sets up AWS credentials from GitHub Secrets
3. Initializes Terraform against a remote S3 backend
4. Runs terraform plan
5. Runs terraform apply with auto approve

The Terraform state lives in a dedicated, versioned S3 bucket, so both my local machine and GitHub Actions are always working from the same picture of what is actually deployed.

---

## Monitoring and cost control

CloudWatch alarms watch the register and list_events Lambda functions for errors, and watch API Gateway for 5xx responses. If anything trips, SNS sends an email right away.

AWS Budgets sends an alert once spending crosses 80 percent and again at 100 percent of a $20 monthly threshold, so there is no surprise bill.

CloudWatch Logs captures every Lambda invocation automatically, which made debugging a lot easier while building this.

---

## Running it locally

### What you need
- Terraform 1.5.0 or newer
- AWS CLI configured with credentials
- Python 3.12 for working on the Lambda functions

### Deploying manually

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Testing an endpoint

```bash
curl https://yibiebjui9.execute-api.us-east-1.amazonaws.com/dev/events
```

---

## Why I built it this way

DynamoDB instead of RDS. The way this app reads data, looking up one event by ID, or looking up all registrations for one event, fits DynamoDB's partition and sort key model naturally, without needing joins. On demand billing also means it costs nothing while sitting idle.

AWS_PROXY integration for Lambda. This gives each function full control over its own HTTP response, status codes, headers, error messages, instead of relying on API Gateway mapping templates.

One shared IAM role for all four Lambdas. Reasonable for a project this size. A bigger system would probably split this into separate roles per function for tighter permissions.

S3 static hosting instead of CloudFront. Good enough for a capstone demo. CloudFront would be the obvious next step if this needed HTTPS and edge caching for real users.

SES in sandbox mode. Right now emails only go out to addresses that have been manually verified in AWS. Getting out of sandbox mode just takes a short approval request to AWS.

---

## What I would add next

- CloudFront and HTTPS for the frontend
- Separate IAM roles per Lambda function
- An admin view to see registrations across every event at once
- A waitlist option for events that are full
- Automated tests running inside the CI/CD pipeline

---

## Author

Ethel Agubama Akanzire
Built as a capstone project for the Azubi Africa AWS Cloud Infrastructure Programme.
