"""
discord - Discord-related utilities and exceptions
"""

from .stdExceptions import (
    CommandError,
    MissingRequiredParam,
    InvalidParamType,
    InvalidParamValue,
    InvalidCommandSyntax,
    CommandNotAllowed,
    UnknownCommand,
    JsonParseError,
    CreationFailed,
    AlreadyExists,
)

__all__ = [
    'CommandError',
    'MissingRequiredParam',
    'InvalidParamType',
    'InvalidParamValue',
    'InvalidCommandSyntax',
    'CommandNotAllowed',
    'UnknownCommand',
    'JsonParseError',
    'CreationFailed',
    'AlreadyExists',
]
