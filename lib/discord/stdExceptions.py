

class CommandError(Exception):
    """Base error for script commands."""
    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


class MissingRequiredParam(CommandError):
    def __init__(self, param: str):
        super().__init__(f"Missing required parameter: `{param}`")


class InvalidParamType(CommandError):
    def __init__(self, param: str, expected: str):
        super().__init__(f"Invalid type for `{param}`. Expected: {expected}")


class InvalidParamValue(CommandError):
    def __init__(self, param: str, reason: str):
        super().__init__(f"Invalid value for `{param}`: {reason}")


class InvalidCommandSyntax(CommandError):
    def __init__(self, hint: str):
        super().__init__(f"Invalid command format. {hint}")


class CommandNotAllowed(CommandError):
    def __init__(self, cmd_name: str):
        super().__init__(f"Command not allowed: `{cmd_name}`")


class UnknownCommand(CommandError):
    def __init__(self, cmd_name: str):
        super().__init__(f"Unknown command: `{cmd_name}`")


class JsonParseError(CommandError):
    def __init__(self):
        super().__init__("Invalid JSON format. Please check your brackets/quotes.")

class CreationFailed(CommandError):
    def __init__(self, item_type: str, name: str):
        super().__init__(f"Could not create {item_type}: `{name}`. Please try again or check server permissions.")

class AlreadyExists(CommandError):
    def __init__(self, item_type: str, name: str):
        super().__init__(f"{item_type} already exists: `{name}`")

class NotFoundError(CommandError):
    def __init__(self, entity_type: str, identifier: str):
        super().__init__(f"{entity_type} not found: `{identifier}`")