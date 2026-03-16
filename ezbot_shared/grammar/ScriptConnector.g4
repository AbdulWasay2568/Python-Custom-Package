grammar ScriptConnector;

options { caseInsensitive = true; }

// ===========================
// Parser rules
// ===========================

script
  : NEWLINE* (command NEWLINE*)* EOF
  ;

command
  : messageStmt
  | agreementCommand
  | verifyStmt
  | letStmt
  | ifStmt
  | sendCaptchaStmt
  | sendSurveyStmt

  // server setup commands
  | createRoleStmt
  | assignPermissionStmt
  | createChannelStmt
  | removePermissionStmt
  | deleteVoiceChannelStmt
  | deleteCategoryStmt
  | setCategoryStmt
  | setChannelRoleStmt
  | getChannelInfoStmt
  | setChannelVisibilityStmt
  | setChannelMemberStmt
  | createCategoryStmt
  | assignRoleStmt
  | deleteRoleStmt
  | editRoleStmt
  | editChannelStmt
  | editCategoryStmt
  | removeRoleFromUserStmt
  | kickMemberStmt
  | banMemberStmt
  | unbanMemberStmt
  | moveUserToVoiceStmt
  | disconnectUserFromVoiceStmt
  | getMemberInfoStmt
  | timeoutMemberStmt
  | removeTimeoutMemberStmt
  | editMessageStmt
  | deleteMessageStmt
  | bulkDeleteMessagesStmt
  | setVoiceStateStmt
  | createThreadStmt
  | setThreadArchivedStmt
  ;

// --------------------------- /message ---------------------------
// Syntax:
// /message [channel] "text" [attachments=a,b,...] [embeds=x,y,...]
messageStmt
  : SLASHMESSAGE messageBody
  ;

messageBody
  : (ID)? STRING messageTail*
  ;

messageTail
  : ATTACHMENTSKW '=' attachmentList
  | EMBEDSKW '=' attachmentList
  ;

attachmentList
  : attachmentRef (COMMA attachmentRef)*
  ;

// ✅ Allow varRef here so attachments=$file works
attachmentRef
  : FILENAME
  | varRef
  | ID
  | STRING
  ;

// --------------------------- /agreement---------------------------
// Syntax:
// /agreement [2ndButtonLabel] filename|"text"|$var

agreementCommand
  : AGREEMENT (secondButtonLabel)? agreementTarget
  ;

secondButtonLabel
  : ID
  | STRING
  ;

agreementTarget
  : FILENAME
  | FILESTRING
  | varRef
  | STRING
  ;

// --------------------------- /sendcaptcha ---------------------------
// Syntax:
// /sendcaptcha [retries=3]
sendCaptchaStmt
  : SENDCAPTCHA (captchaArg)*
  ;

captchaArg
  : RETRIESKW EQ (INT | varRef)
  ;

// --------------------------- /verifyemail ---------------------------
verifyStmt
  : VERIFYEMAIL (STRING)?
  ;

// --------------------------- /verifycode ---------------------------
// Syntax:
// /let bool = /verifycode "anything"
verifyCodeExpr
  : VERIFYCODE (ID | STRING)
  ;

agreementExpr
  : AGREEMENT (secondButtonLabel)? agreementTarget
  ;


// --------------------------- let statement ---------------------------
// /let x = 5
// /let x = /verifycode "code"
letStmt
  : LET assignTarget EQ assignment_expr
  ;

assignTarget
  : varRef
  | ID
  ;

// --------------------------- assignment_expr ---------------------------
// Precedence: unary > * / % > + -
assignment_expr
  : additiveAssignmentExpr
  ;

additiveAssignmentExpr
  : multiplicativeAssignmentExpr (('+' | '-') multiplicativeAssignmentExpr)*
  ;

multiplicativeAssignmentExpr
  : unaryAssignmentExpr (('*' | '/' | '%') unaryAssignmentExpr)*
  ;

unaryAssignmentExpr
  : ('+' | '-') unaryAssignmentExpr
  | primary
  ;

primary
  : INT
  | STRING
  | varRef
  | ID
  | verifyCodeExpr
  | agreementExpr
  | '(' assignment_expr ')'
  ;

varRef
  : DOLLAR ID
  ;

// --------------------------- if / then / endif ---------------------------
// Syntax:
// if bool = "true" then
//    /message "ok"
// endif
ifStmt
  : IFKW boolExpr THENKW NEWLINE? (command NEWLINE?)* ENDIFKW NEWLINE?
  ;

boolExpr
  : boolTerm (OR boolTerm)*
  ;

boolTerm
  : boolFactor (AND boolFactor)*
  ;

boolFactor
  : NOT boolFactor
  | '(' boolExpr ')'
  | comparison
  ;

// ✅ IN supports expressions on RHS too
comparison
  : assignment_expr (compareOp assignment_expr)?
  | assignment_expr IN assignment_expr
  ;

compareOp
  : LE | GE | NE2 | NE | LT | GT | EQ
  ;

// --------------------------- /SendSurvey ---------------------------
// /SendSurvey {
//   /let $email = "Your email address?" : text
//   /let team = "Team?" : mcq ["A","B"]
// }


sendSurveyStmt
  : SENDSURVEY LBRACE NEWLINE* (surveyItem NEWLINE*)* RBRACE
  ;

surveyItem
  : surveyLetDef
  ;

surveyLetDef
  : LET assignTarget EQ STRING COLON surveyKindInline SEMI?
  ;

surveyKindInline
  : TEXTKW
  | MCQKW LBRACK stringList RBRACK
  ;


stringList
  : STRING (COMMA STRING)*
  ;

// ===========================
// Server setup commands
// ===========================

createRoleStmt
  : CREATEROLE STRING
  ;

editRoleStmt
  : EDITROLE STRING STRING
  ;

deleteRoleStmt
  : DELETEROLE STRING
  ;

removeRoleFromUserStmt
  : REMOVEROLEFROMUSER STRING STRING
  ;

assignPermissionStmt
  : ASSIGNPERMISSION STRING STRING
  ;

removePermissionStmt
  : REMOVEPERMISSION STRING STRING
  ;

createChannelStmt
  : CREATECHANNEL STRING STRING
  ;

getChannelInfoStmt
  : GETCHANNELINFO STRING
  ;

getMemberInfoStmt
  : GETMEMBERINFO (STRING)*
  ;

deleteVoiceChannelStmt
  : DELETEVOICECHANNEL STRING
  ;

createCategoryStmt
  : CREATECATEGORY STRING
  ;

deleteCategoryStmt
  : DELETECATEGORY STRING
  ;

setCategoryStmt
  : SETCATEGORY STRING STRING
  ;

setChannelRoleStmt
  : SETCHANNELROLE STRING STRING STRING
  ;

setChannelVisibilityStmt
  : SETCHANNELVISIBILITY STRING STRING
  ;

setChannelMemberStmt
  : SETCHANNELMEMBER STRING STRING STRING
  ;

editChannelStmt
  : EDITCHANNEL STRING STRING
  ;

editCategoryStmt
  : EDITCATEGORY STRING STRING
  ;

assignRoleStmt
  : ASSIGNROLE STRING
  ;

kickMemberStmt
  : KICKMEMBER STRING
  ;

banMemberStmt
  : BANMEMBER STRING
  ;

unbanMemberStmt
  : UNBANMEMBER STRING
  ;

moveUserToVoiceStmt
  : MOVEUSERTOVOICE STRING STRING
  ;

disconnectUserFromVoiceStmt
  : DISCONNECTUSERFROMVOICE STRING STRING
  ;

timeoutMemberStmt
  : TIMEOUTMEMBER STRING duration (STRING)?
  ;

removeTimeoutMemberStmt
  : REMOVETIMEOUTMEMBER STRING
  ;

editMessageStmt
  : EDITMESSAGE STRING STRING
  ;

deleteMessageStmt
  : DELETEMESSAGE STRING
  ;

bulkDeleteMessagesStmt
  : BULKDELETEMESSAGES STRING (STRING)*
  ;

setVoiceStateStmt
  : SETVOICESTATE STRING STRING
  ;

createThreadStmt
  : CREATETHREAD STRING STRING duration
  ;

setThreadArchivedStmt
  : SETTHREADARCHIVED STRING BOOL
  ;

duration
  : (INT | varRef) DURATION_UNIT
  ;

// ===========================
// Lexer rules
// ===========================

IFKW       : 'if';
THENKW     : 'then';
ENDIFKW    : 'endif';

SLASHMESSAGE  : '/message';
ATTACHMENTSKW : 'attachments';
EMBEDSKW      : 'embeds';

AGREEMENT   : '/agreement';
VERIFYEMAIL : '/verifyemail';
VERIFYCODE  : '/verifycode';
SENDCAPTCHA : '/sendcaptcha';
RETRIESKW   : 'retries';

SENDSURVEY  : '/SendSurvey';

TEXTKW      : 'text';
MCQKW       : 'mcq';

NOT        : 'not';
AND        : 'and';
OR         : 'or';
IN         : 'in';

LET         : '/let';
DOLLAR      : '$';

COMMA       : ',';

LBRACE      : '{';
RBRACE      : '}';
LBRACK      : '[';
RBRACK      : ']';
COLON       : ':';
SEMI        : ';';

// ---- ServerSetup keywords ----
CREATEROLE            : '/CreateRole';
ASSIGNPERMISSION      : '/AssignPermission';
CREATECHANNEL         : '/CreateChannel';
REMOVEPERMISSION      : '/RemovePermission';
DELETEVOICECHANNEL    : '/DeleteVoiceChannel';
DELETECATEGORY        : '/DeleteCategory';
SETCATEGORY           : '/SetCategory';
GETCHANNELINFO        : '/GetChannelInfo';
GETMEMBERINFO         : '/GetMemberInfo';
SETCHANNELROLE        : '/SetChannelRole';
SETCHANNELVISIBILITY  : '/SetChannelVisibility';
SETCHANNELMEMBER      : '/SetChannelMember';
CREATECATEGORY        : '/CreateCategory';
ASSIGNROLE            : '/AssignRole';
DELETEROLE            : '/DeleteRole';
EDITROLE              : '/EditRole';
EDITCHANNEL           : '/EditChannel';
EDITCATEGORY          : '/EditCategory';
REMOVEROLEFROMUSER    : '/RemoveRoleFromUser';
KICKMEMBER            : '/KickMember';
BANMEMBER             : '/BanMember';
UNBANMEMBER           : '/UnbanMember';
MOVEUSERTOVOICE       : '/MoveUserToVoice';
DISCONNECTUSERFROMVOICE : '/DisconnectUserFromVoice';
TIMEOUTMEMBER         : '/TimeoutMember';
REMOVETIMEOUTMEMBER   : '/RemoveTimeoutMember';
EDITMESSAGE           : '/EditMessage';
DELETEMESSAGE         : '/DeleteMessage';
BULKDELETEMESSAGES    : '/BulkDeleteMessages';
SETVOICESTATE         : '/SetVoiceState';
CREATETHREAD          : '/CreateThread';
SETTHREADARCHIVED     : '/SetThreadArchived';

// ---- Duration units ----
DURATION_UNIT
  : 'sec' | 'secs' | 'second' | 'seconds'
  | 'min' | 'mins' | 'minute' | 'minutes'
  | 'hour' | 'hours' | 'hr' | 'hrs'
  | 'day' | 'days' | 'd'
  | 'week' | 'weeks' | 'wk' | 'wks'
  | 'month' | 'months'
  | 'yr' | 'yrs' | 'year' | 'years'
  ;

// ---- Operators ----
LE   : '<=';
GE   : '>=';
NE2  : '<>';
NE   : '!=';
LT   : '<';
GT   : '>';
EQ   : '=';

// ---- Literals ----
INT  : [0-9]+;

// Filenames or patterns with a dot (supports *, e.g. *.txt, scripts/*/tos.txt)
FILENAME : [a-z0-9_./\\*-]+ '.' [a-z0-9_.-]+;

// Quoted file patterns (must come BEFORE STRING to take precedence)
FILESTRING
 : '"' [a-z0-9_./\\*-]+ '.' [a-z0-9_.-]+ '"'
 | '\'' [a-z0-9_./\\*-]+ '.' [a-z0-9_.-]+ '\''
 ;

// BOOL must come before ID to take precedence
BOOL : 'true' | 'True' | 'TRUE' | 'false' | 'False' | 'FALSE';

// ID should come after all keywords and BOOL
ID       : [a-z_][a-z0-9_]*;

// Robust string: supports "..." and '...' with escapes, plus "..." curly quotes
STRING
 : '"' (ESC | ~["\\\r\n])* '"'
 | '\'' (ESC | ~['\\\r\n])* '\''
 | '"' (ESC | ~["\\\r\n])* '"'
 ;

fragment ESC : '\\' [btnrf"'\\];

COMMENT : '#' ~[\r\n]* -> skip;

// ✅ spaces OR tabs already supported
WS      : [ \t]+       -> skip;

NEWLINE : ('\r'? '\n')+;
