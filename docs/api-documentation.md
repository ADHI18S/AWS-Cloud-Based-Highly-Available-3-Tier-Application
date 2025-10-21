text
#  API Documentation

## Base URL

Internal Application Load Balancer DNS  
e.g., `http://internal-app-alb-xxxxxx.us-east-2.elb.amazonaws.com:8000`

## Endpoints

### Health Check

- **GET /health**  
Returns basic health status.

Response:
{
"status": "healthy",
"message": "Flask app is running",
"timestamp": "2025-10-21T12:00:00"
}



### Get Exam Results

- **POST /api/result**  
Parameters (JSON body):
{
"registration_number": "2024CS001",
"date_of_birth": "2003-05-15"
}


Success Response (200):
{
"success": true,
"student": {
"name": "Rajesh Kumar",
"registration_number": "2024CS001"
},
"results": [
{
"semester": "Semester 1",
"subject_code": "CS101",
"subject_name": "Programming in C",
"internal_marks": 45,
"external_marks": 72,
"total_marks": 117,
"grade": "A+",
"status": "PASS"
}
]
}


Error Response (404):
{
"success": false,
"message": "Invalid registration number or date of birth"
}


---

## Usage Notes

- API expects JSON requests.
- Date format: `YYYY-MM-DD`.
- Authentication via registration number and date of birth.
- Endpoint handles data validation and errors.

---

Last updated: October 2025