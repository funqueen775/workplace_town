extends Node


func _ready() -> void:
	ApiClient._queue.clear()
	ApiClient._resume_session_id = "old-session"
	ApiClient._session_id = "old-session"
	ApiClient._session_token = "expired-token"
	ApiClient._session_confirmed = false
	ApiClient._on_request_completed(HTTPRequest.RESULT_SUCCESS, 403,
		PackedStringArray(), PackedByteArray())
	if ApiClient.current_session_id() != "old-session":
		push_error("API_SESSION_RECOVERY_FAIL: unrelated response changed session")
		get_tree().quit(1)
		return
	ApiClient._in_flight_kind = "session"
	ApiClient._in_flight = true
	ApiClient._mode = "mock"
	ApiClient._on_request_completed(HTTPRequest.RESULT_SUCCESS, 403,
		PackedStringArray(), PackedByteArray())
	if ApiClient.current_session_id() != "" or ApiClient._resume_session_id != "":
		push_error("API_SESSION_RECOVERY_FAIL: expired session was not cleared")
		get_tree().quit(1)
		return
	print("API_SESSION_RECOVERY_PASS")
	get_tree().quit(0)
