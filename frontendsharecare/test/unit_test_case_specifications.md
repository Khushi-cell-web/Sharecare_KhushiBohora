# Unit Test Case Specifications (15 Unit Tests)

This document provides formal test case write-ups for the 15 unit test modules implemented in this project.
Latest execution status for all listed cases: pass.

## Test 01 - User Login Flow (`user_login_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT01 |
| Objective | Verify login request format, successful authentication response parsing, and authentication error handling. |
| Description | Checks that login sends correct payload fields, parses tokens on success, and throws API exception for invalid credentials. |
| Action | 1) Open `user_login_test.dart`. 2) Prepare mocked login endpoint (`/auth/login/`). 3) Run success scenario with valid credentials and status 200. 4) Validate token and user fields are decoded correctly. 5) Run invalid credential scenario with status 401. 6) Execute payload assertion test and verify only expected keys are sent. |
| Input | `username`: `alice` / `payloadUser`; `password`: valid and invalid values; mocked status codes: `200`, `401`. |
| Expected Output | Login success returns token payload; invalid credentials raise `ShareCareApiException(401)`; request body contains expected username/password keys. |
| Result | pass |

## Test 02 - User Registration Flow (`user_registration_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT02 |
| Objective | Validate registration input checks, duplicate-email handling, and successful registration payload behavior. |
| Description | Ensures required registration fields are validated, duplicate email is handled, and valid user registration returns expected data. |
| Action | 1) Open `user_registration_test.dart`. 2) Execute required-field validation test. 3) Mock duplicate email response (`400`) and execute registration request. 4) Mock successful registration response (`201`) and run valid registration scenario. 5) Verify sent payload fields (`username`, `email`, `role`, names, phone). |
| Input | `username`, `email`, `password`, `passwordConfirm`, `role`, optional `firstName`, `lastName`, `phone`; mocked status codes: `400`, `201`. |
| Expected Output | Missing fields are detected; duplicate email returns API exception; valid registration succeeds and payload formatting is correct. |
| Result | pass |

## Test 03 - OTP Send Flow (`otp_send_flow_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT03 |
| Objective | Verify OTP send request payload, success behavior, and internal server error handling. |
| Description | Tests OTP dispatch endpoint behavior for success and server failure scenarios. |
| Action | 1) Open `otp_send_flow_test.dart`. 2) Mock OTP endpoint (`/auth/forgot-password/`) with status 200 and run send flow. 3) Assert `user_id` and `email` are sent correctly. 4) Mock status 500 response and run failure case. 5) Verify error is propagated as `ShareCareApiException`. |
| Input | `user_id`: `42`/`12`; `email`: valid format values; mocked status codes: `200`, `500`. |
| Expected Output | OTP request is sent correctly on success; for status 500, API exception is thrown and captured by test assertions. |
| Result | pass |

## Test 04 - OTP Verification Flow (`otp_verification_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT04 |
| Objective | Validate OTP verification request payload and behavior for valid, invalid, and expired OTP. |
| Description | Confirms correct request body and proper exception mapping for invalid/expired verification responses. |
| Action | 1) Open `otp_verification_test.dart`. 2) Mock verify endpoint (`/auth/verify-otp/`) with status 200 and run valid OTP test. 3) Assert payload contains `user_id`, `email`, `otp`. 4) Mock status 400 for invalid OTP and assert exception. 5) Mock status 410 for expired OTP and assert exception. |
| Input | `user_id`: `21`; `email`: `otp.valid@sharecare.org`; `otp`: `123456`, `000000`, `999999`; mocked status codes: `200`, `400`, `410`. |
| Expected Output | Valid OTP passes; invalid and expired OTP cases throw `ShareCareApiException` with corresponding status codes. |
| Result | pass |

## Test 05 - Password Reset Request (`password_reset_request_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT05 |
| Objective | Confirm reset-request payload correctness, local email validation, and backend error propagation. |
| Description | Ensures reset request API is called with correct body and invalid email is blocked before API call. |
| Action | 1) Open `password_reset_request_test.dart`. 2) Mock forgot-password endpoint status 200 and run request. 3) Validate request payload fields. 4) Run invalid email scenario and confirm local `FormatException`. 5) Mock status 404 and ensure backend error is surfaced. |
| Input | `user_id`: `88`; `email`: valid and invalid values; mocked status codes: `200`, `404`. |
| Expected Output | Valid reset request succeeds; invalid email fails before network call; unknown user path throws API exception (`404`). |
| Result | pass |

## Test 06 - Password Reset Confirmation (`password_reset_confirmation_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT06 |
| Objective | Validate OTP-confirmed password reset sequence and local OTP format/TTL protections. |
| Description | Tests chained verify-OTP + reset-password flow and rejects malformed/expired OTP before API operations. |
| Action | 1) Open `password_reset_confirmation_test.dart`. 2) Mock verify OTP status 200 and reset password status 200. 3) Execute confirmation flow with valid OTP and matching passwords. 4) Verify body for both API calls. 5) Execute invalid OTP format case and assert `FormatException`. 6) Execute expired OTP case and assert `TimeoutException`. |
| Input | `user_id`: `55`; `email`: `confirm@sharecare.org`; `otp`: valid `123456` and invalid values; `new_password`; mocked status codes: `200` for verify/reset. |
| Expected Output | Valid sequence updates password successfully; malformed OTP and expired OTP are rejected locally with proper exceptions. |
| Result | pass |

## Test 07 - Donation Item Creation (`donation_item_creation_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT07 |
| Objective | Validate donation-item input rules, request payload correctness, and API failure handling. |
| Description | Covers field validation, successful donation creation (`201`), and invalid payload error mapping (`400`). |
| Action | 1) Open `donation_item_creation_test.dart`. 2) Run local validation assertions for missing category/type and zero quantity. 3) Mock create endpoint (`/donations/donations/`) with status 201 and execute create flow. 4) Verify request body structure and values. 5) Mock status 400 and verify exception behavior. |
| Input | `category`: `clothes`; `donationType`: `material`; `quantity`: `5`; `description`: sample text; mocked status codes: `201`, `400`. |
| Expected Output | Invalid local inputs are blocked; valid payload creates item and returns expected response; status 400 triggers API exception. |
| Result | pass |

## Test 08 - Food Donation Expiry Validation (`food_donation_expiry_validation_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT08 |
| Objective | Ensure food donations enforce expiry date requirements and serialize valid expiry in payload. |
| Description | Verifies missing/past expiry rejection and future expiry acceptance with proper payload key inclusion. |
| Action | 1) Open `food_donation_expiry_validation_test.dart`. 2) Run missing expiry case and assert validation message. 3) Run past-date case and assert rejection message. 4) Mock create endpoint status 201 and run future-expiry creation. 5) Assert `expiry_date` exists in request body and date value is correct. |
| Input | `category`: `food`; `donationType`: `material`; `expiryDate`: null/past/future; mocked status code: `201`. |
| Expected Output | Missing/past expiry inputs are rejected; valid future expiry is accepted and sent in API payload. |
| Result | pass |

## Test 09 - Donation History Fetch (`donation_history_fetch_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT09 |
| Objective | Validate donation history parsing for populated, empty, and malformed responses. |
| Description | Confirms transaction list parsing and robust behavior for edge-case response formats. |
| Action | 1) Open `donation_history_fetch_test.dart`. 2) Mock history endpoint (`/donations/history/`) with mixed valid records (status 200). 3) Assert parsed list size and status helpers. 4) Mock empty list and assert empty result. 5) Mock malformed payload and assert parse error/exception. |
| Input | Auth header token; mocked history payloads with status code `200` (valid, empty, malformed shapes). |
| Expected Output | Valid history parses correctly; empty history yields empty list; malformed data throws parsing exception. |
| Result | pass |

## Test 10 - Your Impact Calculation (`your_impact_calculation_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT10 |
| Objective | Confirm completed/confirmed donations are counted correctly for user impact metrics. |
| Description | Ensures impact counter logic produces expected totals for mixed, none-completed, and empty history sets. |
| Action | 1) Open `your_impact_calculation_test.dart`. 2) Mock history with completed/confirmed/pending records and execute count logic. 3) Assert count matches expected completed+confirmed total. 4) Mock only pending history and assert zero. 5) Mock empty list and assert zero. |
| Input | Donation history responses with status code `200`; varying transaction statuses (`completed`, `confirmed`, `pending`). |
| Expected Output | Impact count includes only completed/confirmed records; returns zero where no eligible records exist. |
| Result | pass |

## Test 11 - Request Browsing (`request_browsing_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT11 |
| Objective | Validate donation request list parsing and query-filter forwarding behavior. |
| Description | Confirms filter values are sent to API and response parsing handles valid/empty/malformed datasets. |
| Action | 1) Open `request_browsing_test.dart`. 2) Mock request list endpoint (`/donations/requests/`) with valid records and execute filtered query. 3) Assert returned objects and query params (`status`, `category`, `urgency`). 4) Mock empty list and verify empty result. 5) Mock malformed list item and verify parsing exception. |
| Input | Filters: `status=open`, `category=food`, `urgency=High`; mocked status code `200` with multiple payload shapes. |
| Expected Output | Filters are correctly forwarded; valid list parses; empty list is handled; malformed payload throws exception. |
| Result | pass |

## Test 12 - Offer Donation Flow (`offer_donation_flow_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT12 |
| Objective | Verify offer input validation, offer creation payload correctness, and forbidden response handling. |
| Description | Ensures required offer fields are validated and offer API interactions behave correctly for success/failure states. |
| Action | 1) Open `offer_donation_flow_test.dart`. 2) Execute local input validation for missing request id/type/quantity. 3) Mock offers endpoint (`/donations/offers/`) with status 201 and create offer. 4) Assert payload fields including `fulfillment_type`. 5) Mock status 403 and assert API exception behavior. |
| Input | `donationRequestId`: `9`; `type`: `food`; `quantity`: `10`; `message`: sample text; mocked status codes: `201`, `403`. |
| Expected Output | Invalid inputs are caught; valid offer creation succeeds and payload is accurate; forbidden response raises exception. |
| Result | pass |

## Test 13 - Volunteer Task Fetch (`volunteer_task_fetch_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT13 |
| Objective | Validate pending volunteer task list parsing for valid, empty, and malformed task payloads. |
| Description | Confirms volunteer task endpoint data is parsed correctly and malformed records are rejected. |
| Action | 1) Open `volunteer_task_fetch_test.dart`. 2) Mock pending-task endpoint (`/volunteers/pending-tasks/`) with valid task and run fetch. 3) Assert parsed fields (`pickup`, `delivery`, `status`). 4) Mock empty array and assert empty list. 5) Mock malformed task item and assert parse exception. |
| Input | Auth header token; mocked status code `200` with valid/empty/malformed task arrays. |
| Expected Output | Valid tasks parse correctly; empty list handled safely; malformed payload fails with parsing exception. |
| Result | pass |

## Test 14 - Volunteer Task Update (`volunteer_task_update_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT14 |
| Objective | Verify volunteer task status updates (`picked`, `delivered`) and invalid transition error behavior. |
| Description | Tests patch request body correctness and exception mapping for failed updates. |
| Action | 1) Open `volunteer_task_update_test.dart`. 2) Mock task update endpoint (`/volunteers/tasks/{id}/`) with status 200 for `picked` and execute update. 3) Assert request body contains expected `task_status`. 4) Mock status 200 for `delivered` and verify delivery flags. 5) Mock status 400 invalid transition and assert API exception. |
| Input | `taskId`: `77`; `taskStatus`: `picked`, `delivered`; mocked status codes: `200`, `400`. |
| Expected Output | Valid status changes persist and parse correctly; invalid transition returns `ShareCareApiException(400)`. |
| Result | pass |

## Test 15 - Reward Points System (`reward_points_system_test.dart`)

| Field | Details |
|---|---|
| Test ID | UT15 |
| Objective | Validate reward point calculation for delivered urgent, non-delivered, and normal delivered tasks. |
| Description | Ensures points are only awarded on delivered tasks and values match task-defined delivery points. |
| Action | 1) Open `reward_points_system_test.dart`. 2) Mock task update response with delivered urgent task and run points update calculation. 3) Assert point increment is applied correctly. 4) Run non-delivered task scenario and assert no increment. 5) Run normal delivered task and assert standard points behavior. |
| Input | `currentPoints`: sample values; volunteer task payloads with `task_status` and `delivery_points`; mocked status code `200` for delivered update flow. |
| Expected Output | Delivered urgent tasks add configured points; non-delivered tasks add zero; normal delivered tasks add standard points. |
| Result | pass |
