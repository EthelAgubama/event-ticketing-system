# Event Registration & Ticketing System

A serverless REST API and web application for event registration and ticketing, built entirely on AWS. Replaces manual Microsoft Forms + Excel tracking with a scalable, automated, infrastructure-as-code system.

**Live site:** http://event-ticketing-frontend-871049984358.s3-website-us-east-1.amazonaws.com
**Live API:** https://yibiebjui9.execute-api.us-east-1.amazonaws.com/dev/events

Built as a capstone project for the Azubi Africa AWS Cloud Infrastructure Programme.

---

## Overview

This project lets organizers publish events and lets participants register for them through a simple web form. Every piece of infrastructure — from the database to the API to the frontend hosting — is provisioned and version-controlled with Terraform, and deployments are automated through a GitHub Actions CI/CD pipeline.

---

## Architecture

```
GitHub Repository
       │
       ▼
GitHub Actions (CI/CD)  ──▶  Terraform Apply
       │
       ▼
┌─────────────────────────────────────────────┐
│                  AWS Cloud                    │
│                                                │
│  API Gateway (REST)                           │
│    ├── GET  /events                           │
│    ├── GET  /events/{eventId}                 │
│    ├── POST /events/{eventId}/register         │
│    └── GET  /events/{eventId}/registrations    │
│         │                                     │
│         ▼                                     │
│  Lambda Functions (Python 3.12)               │
│    ├── list_events                            │
│    ├── get_event                              │
│    ├── register                               │
│    └── list_registrations                     │
│         │                                     │
│         ▼                                     │
│  DynamoDB                                     │
│    ├── Events table                           │
│    └── Registrations table                    │
│                                                │
│  Amazon SES ── confirmation emails             │
│  CloudWatch ── logs + alarms                  │
│  SNS ── admin alert notifications             │
│  AWS Budgets ── cost monitoring               │
│  S3 ── static frontend hosting                │
└─────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure as Code | Terraform |
| Compute | AWS Lambda (Python 3.12) |
| API | Amazon API Gateway (REST) |
| Database | Amazon DynamoDB |
| Frontend Hosting | Amazon S3 (static website) |
| Email | Amazon SES |
| Monitoring | Amazon CloudWatch + SNS |
| Cost Control | AWS Budgets |
| CI/CD | GitHub Actions |
| Frontend | HTML, CSS, vanilla JavaScript |

---

## Repository Structure

```
event-ticketing-system/
├── terraform/
│   ├── main.tf              # Provider + S3 remote backend config
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # API and frontend URLs
│   ├── dynamodb.tf          # Events & Registrations tables
│   ├── iam.tf                # Lambda execution role + policies
│   ├── lambda.tf             # All 4 Lambda function definitions
│   ├── api_gateway.tf        # REST API, resources, methods, CORS
│   ├── frontend.tf           # S3 static website hosting
│   ├── budget.tf             # AWS Budgets cost alert
│   └── monitoring.tf         # CloudWatch alarms + SNS topic
├── lambda/
│   ├── list_events/
│   ├── get_event/
│   ├── register/
│   └── list_registrations/
├── frontend/
│   └── index.html            # Registration UI
├── .github/
│   └── workflows/
│       └── deploy.yml        # CI/CD pipeline
└── README.md
```

---

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/events` | List all events |
| `GET` | `/events/{eventId}` | Get a single event's details |
| `POST` | `/events/{eventId}/register` | Register a participant (body: `name`, `email`) |
| `GET` | `/events/{eventId}/registrations` | List all registrations for an event |

### Example: Register for an event

```bash
curl -X POST "https://yibiebjui9.execute-api.us-east-1.amazonaws.com/dev/events/evt001/register" \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Doe", "email": "jane@example.com"}'
```

**Business logic enforced server-side:**
- Rejects registration if the event doesn't exist (`404`)
- Rejects registration if the event is at capacity (`409`)
- Rejects duplicate registration by the same email for the same event (`409`)
- On success, atomically increments the event's registered count
- On success, sends a confirmation email via SES

---

## Data Model

**Events table**
| Attribute | Type | Notes |
|---|---|---|
| `eventId` (PK) | String | |
| `eventName` | String | |
| `eventDate` | String | ISO date |
| `capacity` | Number | |
| `registeredCount` | Number | Incremented atomically on registration |
| `status` | String | Available / Limited / Full |

**Registrations table**
| Attribute | Type | Notes |
|---|---|---|
| `eventId` (PK) | String | |
| `email` (SK) | String | Composite key prevents duplicate registration |
| `name` | String | |
| `timestamp` | String | ISO 8601, UTC |
| `status` | String | |

---

## CI/CD Pipeline

Every push to `main` triggers a GitHub Actions workflow that:
1. Checks out the repository
2. Configures AWS credentials (via GitHub Secrets)
3. Initializes Terraform against a remote S3 backend
4. Runs `terraform plan`
5. Runs `terraform apply -auto-approve`

Terraform state is stored remotely in a dedicated, versioned S3 bucket so that both local development and CI/CD share a single, consistent source of truth about deployed infrastructure.

---

## Monitoring & Cost Control

- **CloudWatch Alarms** watch for Lambda errors (`register`, `list_events`) and API Gateway 5xx responses, notifying via SNS the moment any error occurs.
- **AWS Budgets** sends an email alert at 80% and 100% of a $20/month spend threshold, preventing unexpected charges on a Free Tier–oriented project.
- **CloudWatch Logs** capture every Lambda invocation automatically for debugging and auditing.

---

## Local Development

### Prerequisites
- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- Python 3.12 (for Lambda function development)

### Deploy manually

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Test an endpoint

```bash
curl https://yibiebjui9.execute-api.us-east-1.amazonaws.com/dev/events
```

---

## Design Decisions

- **DynamoDB over RDS** — the access patterns (lookup by event ID, lookup registrations by event ID) map cleanly onto DynamoDB's partition/sort key model without needing joins, and on-demand billing keeps costs at zero when idle.
- **AWS_PROXY Lambda integration** — gives each Lambda full control over the HTTP response (status codes, headers, error bodies) rather than mapping templates in API Gateway.
- **Shared IAM role across Lambdas** — appropriate at this project's scale; a larger system would likely split into per-function roles for tighter least-privilege scoping.
- **S3 static hosting over CloudFront** — sufficient for a capstone demo; CloudFront would be the natural next step for HTTPS and edge caching in a production deployment.
- **SES sandbox mode** — emails currently only deliver to verified addresses; moving to production access is a one-time AWS approval step away.

---

## Future Improvements

- CloudFront + HTTPS for the frontend
- Per-function IAM roles for tighter least-privilege access
- Admin dashboard for viewing registrations across all events
- Waitlist support for full events
- Automated integration tests in the CI/CD pipeline

---

## Author

**Ethel Agubama Akanzire**
Built as a capstone project for the Azubi Africa AWS Cloud Infrastructure Programme.