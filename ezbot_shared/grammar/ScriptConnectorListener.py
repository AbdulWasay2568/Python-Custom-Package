# Generated from ScriptConnector.g4 by ANTLR 4.13.2
from antlr4 import *
if "." in __name__:
    from .ScriptConnectorParser import ScriptConnectorParser
else:
    from ScriptConnectorParser import ScriptConnectorParser

# This class defines a complete listener for a parse tree produced by ScriptConnectorParser.
class ScriptConnectorListener(ParseTreeListener):

    # Enter a parse tree produced by ScriptConnectorParser#script.
    def enterScript(self, ctx:ScriptConnectorParser.ScriptContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#script.
    def exitScript(self, ctx:ScriptConnectorParser.ScriptContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#command.
    def enterCommand(self, ctx:ScriptConnectorParser.CommandContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#command.
    def exitCommand(self, ctx:ScriptConnectorParser.CommandContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#messageStmt.
    def enterMessageStmt(self, ctx:ScriptConnectorParser.MessageStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#messageStmt.
    def exitMessageStmt(self, ctx:ScriptConnectorParser.MessageStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#messageBody.
    def enterMessageBody(self, ctx:ScriptConnectorParser.MessageBodyContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#messageBody.
    def exitMessageBody(self, ctx:ScriptConnectorParser.MessageBodyContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#messageTail.
    def enterMessageTail(self, ctx:ScriptConnectorParser.MessageTailContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#messageTail.
    def exitMessageTail(self, ctx:ScriptConnectorParser.MessageTailContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#attachmentList.
    def enterAttachmentList(self, ctx:ScriptConnectorParser.AttachmentListContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#attachmentList.
    def exitAttachmentList(self, ctx:ScriptConnectorParser.AttachmentListContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#attachmentRef.
    def enterAttachmentRef(self, ctx:ScriptConnectorParser.AttachmentRefContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#attachmentRef.
    def exitAttachmentRef(self, ctx:ScriptConnectorParser.AttachmentRefContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#agreementCommand.
    def enterAgreementCommand(self, ctx:ScriptConnectorParser.AgreementCommandContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#agreementCommand.
    def exitAgreementCommand(self, ctx:ScriptConnectorParser.AgreementCommandContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#secondButtonLabel.
    def enterSecondButtonLabel(self, ctx:ScriptConnectorParser.SecondButtonLabelContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#secondButtonLabel.
    def exitSecondButtonLabel(self, ctx:ScriptConnectorParser.SecondButtonLabelContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#agreementTarget.
    def enterAgreementTarget(self, ctx:ScriptConnectorParser.AgreementTargetContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#agreementTarget.
    def exitAgreementTarget(self, ctx:ScriptConnectorParser.AgreementTargetContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#sendCaptchaStmt.
    def enterSendCaptchaStmt(self, ctx:ScriptConnectorParser.SendCaptchaStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#sendCaptchaStmt.
    def exitSendCaptchaStmt(self, ctx:ScriptConnectorParser.SendCaptchaStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#captchaArg.
    def enterCaptchaArg(self, ctx:ScriptConnectorParser.CaptchaArgContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#captchaArg.
    def exitCaptchaArg(self, ctx:ScriptConnectorParser.CaptchaArgContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#verifyStmt.
    def enterVerifyStmt(self, ctx:ScriptConnectorParser.VerifyStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#verifyStmt.
    def exitVerifyStmt(self, ctx:ScriptConnectorParser.VerifyStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#verifyCodeExpr.
    def enterVerifyCodeExpr(self, ctx:ScriptConnectorParser.VerifyCodeExprContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#verifyCodeExpr.
    def exitVerifyCodeExpr(self, ctx:ScriptConnectorParser.VerifyCodeExprContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#agreementExpr.
    def enterAgreementExpr(self, ctx:ScriptConnectorParser.AgreementExprContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#agreementExpr.
    def exitAgreementExpr(self, ctx:ScriptConnectorParser.AgreementExprContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#letStmt.
    def enterLetStmt(self, ctx:ScriptConnectorParser.LetStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#letStmt.
    def exitLetStmt(self, ctx:ScriptConnectorParser.LetStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#assignTarget.
    def enterAssignTarget(self, ctx:ScriptConnectorParser.AssignTargetContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#assignTarget.
    def exitAssignTarget(self, ctx:ScriptConnectorParser.AssignTargetContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#assignment_expr.
    def enterAssignment_expr(self, ctx:ScriptConnectorParser.Assignment_exprContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#assignment_expr.
    def exitAssignment_expr(self, ctx:ScriptConnectorParser.Assignment_exprContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#additiveAssignmentExpr.
    def enterAdditiveAssignmentExpr(self, ctx:ScriptConnectorParser.AdditiveAssignmentExprContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#additiveAssignmentExpr.
    def exitAdditiveAssignmentExpr(self, ctx:ScriptConnectorParser.AdditiveAssignmentExprContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#multiplicativeAssignmentExpr.
    def enterMultiplicativeAssignmentExpr(self, ctx:ScriptConnectorParser.MultiplicativeAssignmentExprContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#multiplicativeAssignmentExpr.
    def exitMultiplicativeAssignmentExpr(self, ctx:ScriptConnectorParser.MultiplicativeAssignmentExprContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#unaryAssignmentExpr.
    def enterUnaryAssignmentExpr(self, ctx:ScriptConnectorParser.UnaryAssignmentExprContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#unaryAssignmentExpr.
    def exitUnaryAssignmentExpr(self, ctx:ScriptConnectorParser.UnaryAssignmentExprContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#primary.
    def enterPrimary(self, ctx:ScriptConnectorParser.PrimaryContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#primary.
    def exitPrimary(self, ctx:ScriptConnectorParser.PrimaryContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#varRef.
    def enterVarRef(self, ctx:ScriptConnectorParser.VarRefContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#varRef.
    def exitVarRef(self, ctx:ScriptConnectorParser.VarRefContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#ifStmt.
    def enterIfStmt(self, ctx:ScriptConnectorParser.IfStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#ifStmt.
    def exitIfStmt(self, ctx:ScriptConnectorParser.IfStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#boolExpr.
    def enterBoolExpr(self, ctx:ScriptConnectorParser.BoolExprContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#boolExpr.
    def exitBoolExpr(self, ctx:ScriptConnectorParser.BoolExprContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#boolTerm.
    def enterBoolTerm(self, ctx:ScriptConnectorParser.BoolTermContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#boolTerm.
    def exitBoolTerm(self, ctx:ScriptConnectorParser.BoolTermContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#boolFactor.
    def enterBoolFactor(self, ctx:ScriptConnectorParser.BoolFactorContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#boolFactor.
    def exitBoolFactor(self, ctx:ScriptConnectorParser.BoolFactorContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#comparison.
    def enterComparison(self, ctx:ScriptConnectorParser.ComparisonContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#comparison.
    def exitComparison(self, ctx:ScriptConnectorParser.ComparisonContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#compareOp.
    def enterCompareOp(self, ctx:ScriptConnectorParser.CompareOpContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#compareOp.
    def exitCompareOp(self, ctx:ScriptConnectorParser.CompareOpContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#sendSurveyStmt.
    def enterSendSurveyStmt(self, ctx:ScriptConnectorParser.SendSurveyStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#sendSurveyStmt.
    def exitSendSurveyStmt(self, ctx:ScriptConnectorParser.SendSurveyStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#surveyItem.
    def enterSurveyItem(self, ctx:ScriptConnectorParser.SurveyItemContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#surveyItem.
    def exitSurveyItem(self, ctx:ScriptConnectorParser.SurveyItemContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#surveyLetDef.
    def enterSurveyLetDef(self, ctx:ScriptConnectorParser.SurveyLetDefContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#surveyLetDef.
    def exitSurveyLetDef(self, ctx:ScriptConnectorParser.SurveyLetDefContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#surveyKindInline.
    def enterSurveyKindInline(self, ctx:ScriptConnectorParser.SurveyKindInlineContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#surveyKindInline.
    def exitSurveyKindInline(self, ctx:ScriptConnectorParser.SurveyKindInlineContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#stringList.
    def enterStringList(self, ctx:ScriptConnectorParser.StringListContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#stringList.
    def exitStringList(self, ctx:ScriptConnectorParser.StringListContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#createRoleStmt.
    def enterCreateRoleStmt(self, ctx:ScriptConnectorParser.CreateRoleStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#createRoleStmt.
    def exitCreateRoleStmt(self, ctx:ScriptConnectorParser.CreateRoleStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#editRoleStmt.
    def enterEditRoleStmt(self, ctx:ScriptConnectorParser.EditRoleStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#editRoleStmt.
    def exitEditRoleStmt(self, ctx:ScriptConnectorParser.EditRoleStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#deleteRoleStmt.
    def enterDeleteRoleStmt(self, ctx:ScriptConnectorParser.DeleteRoleStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#deleteRoleStmt.
    def exitDeleteRoleStmt(self, ctx:ScriptConnectorParser.DeleteRoleStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#removeRoleFromUserStmt.
    def enterRemoveRoleFromUserStmt(self, ctx:ScriptConnectorParser.RemoveRoleFromUserStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#removeRoleFromUserStmt.
    def exitRemoveRoleFromUserStmt(self, ctx:ScriptConnectorParser.RemoveRoleFromUserStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#assignPermissionStmt.
    def enterAssignPermissionStmt(self, ctx:ScriptConnectorParser.AssignPermissionStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#assignPermissionStmt.
    def exitAssignPermissionStmt(self, ctx:ScriptConnectorParser.AssignPermissionStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#removePermissionStmt.
    def enterRemovePermissionStmt(self, ctx:ScriptConnectorParser.RemovePermissionStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#removePermissionStmt.
    def exitRemovePermissionStmt(self, ctx:ScriptConnectorParser.RemovePermissionStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#createChannelStmt.
    def enterCreateChannelStmt(self, ctx:ScriptConnectorParser.CreateChannelStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#createChannelStmt.
    def exitCreateChannelStmt(self, ctx:ScriptConnectorParser.CreateChannelStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#getChannelInfoStmt.
    def enterGetChannelInfoStmt(self, ctx:ScriptConnectorParser.GetChannelInfoStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#getChannelInfoStmt.
    def exitGetChannelInfoStmt(self, ctx:ScriptConnectorParser.GetChannelInfoStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#getMemberInfoStmt.
    def enterGetMemberInfoStmt(self, ctx:ScriptConnectorParser.GetMemberInfoStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#getMemberInfoStmt.
    def exitGetMemberInfoStmt(self, ctx:ScriptConnectorParser.GetMemberInfoStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#deleteVoiceChannelStmt.
    def enterDeleteVoiceChannelStmt(self, ctx:ScriptConnectorParser.DeleteVoiceChannelStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#deleteVoiceChannelStmt.
    def exitDeleteVoiceChannelStmt(self, ctx:ScriptConnectorParser.DeleteVoiceChannelStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#createCategoryStmt.
    def enterCreateCategoryStmt(self, ctx:ScriptConnectorParser.CreateCategoryStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#createCategoryStmt.
    def exitCreateCategoryStmt(self, ctx:ScriptConnectorParser.CreateCategoryStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#deleteCategoryStmt.
    def enterDeleteCategoryStmt(self, ctx:ScriptConnectorParser.DeleteCategoryStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#deleteCategoryStmt.
    def exitDeleteCategoryStmt(self, ctx:ScriptConnectorParser.DeleteCategoryStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#setCategoryStmt.
    def enterSetCategoryStmt(self, ctx:ScriptConnectorParser.SetCategoryStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#setCategoryStmt.
    def exitSetCategoryStmt(self, ctx:ScriptConnectorParser.SetCategoryStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#setChannelRoleStmt.
    def enterSetChannelRoleStmt(self, ctx:ScriptConnectorParser.SetChannelRoleStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#setChannelRoleStmt.
    def exitSetChannelRoleStmt(self, ctx:ScriptConnectorParser.SetChannelRoleStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#setChannelVisibilityStmt.
    def enterSetChannelVisibilityStmt(self, ctx:ScriptConnectorParser.SetChannelVisibilityStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#setChannelVisibilityStmt.
    def exitSetChannelVisibilityStmt(self, ctx:ScriptConnectorParser.SetChannelVisibilityStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#setChannelMemberStmt.
    def enterSetChannelMemberStmt(self, ctx:ScriptConnectorParser.SetChannelMemberStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#setChannelMemberStmt.
    def exitSetChannelMemberStmt(self, ctx:ScriptConnectorParser.SetChannelMemberStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#editChannelStmt.
    def enterEditChannelStmt(self, ctx:ScriptConnectorParser.EditChannelStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#editChannelStmt.
    def exitEditChannelStmt(self, ctx:ScriptConnectorParser.EditChannelStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#editCategoryStmt.
    def enterEditCategoryStmt(self, ctx:ScriptConnectorParser.EditCategoryStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#editCategoryStmt.
    def exitEditCategoryStmt(self, ctx:ScriptConnectorParser.EditCategoryStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#assignRoleStmt.
    def enterAssignRoleStmt(self, ctx:ScriptConnectorParser.AssignRoleStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#assignRoleStmt.
    def exitAssignRoleStmt(self, ctx:ScriptConnectorParser.AssignRoleStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#kickMemberStmt.
    def enterKickMemberStmt(self, ctx:ScriptConnectorParser.KickMemberStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#kickMemberStmt.
    def exitKickMemberStmt(self, ctx:ScriptConnectorParser.KickMemberStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#banMemberStmt.
    def enterBanMemberStmt(self, ctx:ScriptConnectorParser.BanMemberStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#banMemberStmt.
    def exitBanMemberStmt(self, ctx:ScriptConnectorParser.BanMemberStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#unbanMemberStmt.
    def enterUnbanMemberStmt(self, ctx:ScriptConnectorParser.UnbanMemberStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#unbanMemberStmt.
    def exitUnbanMemberStmt(self, ctx:ScriptConnectorParser.UnbanMemberStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#moveUserToVoiceStmt.
    def enterMoveUserToVoiceStmt(self, ctx:ScriptConnectorParser.MoveUserToVoiceStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#moveUserToVoiceStmt.
    def exitMoveUserToVoiceStmt(self, ctx:ScriptConnectorParser.MoveUserToVoiceStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#disconnectUserFromVoiceStmt.
    def enterDisconnectUserFromVoiceStmt(self, ctx:ScriptConnectorParser.DisconnectUserFromVoiceStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#disconnectUserFromVoiceStmt.
    def exitDisconnectUserFromVoiceStmt(self, ctx:ScriptConnectorParser.DisconnectUserFromVoiceStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#timeoutMemberStmt.
    def enterTimeoutMemberStmt(self, ctx:ScriptConnectorParser.TimeoutMemberStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#timeoutMemberStmt.
    def exitTimeoutMemberStmt(self, ctx:ScriptConnectorParser.TimeoutMemberStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#removeTimeoutMemberStmt.
    def enterRemoveTimeoutMemberStmt(self, ctx:ScriptConnectorParser.RemoveTimeoutMemberStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#removeTimeoutMemberStmt.
    def exitRemoveTimeoutMemberStmt(self, ctx:ScriptConnectorParser.RemoveTimeoutMemberStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#editMessageStmt.
    def enterEditMessageStmt(self, ctx:ScriptConnectorParser.EditMessageStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#editMessageStmt.
    def exitEditMessageStmt(self, ctx:ScriptConnectorParser.EditMessageStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#deleteMessageStmt.
    def enterDeleteMessageStmt(self, ctx:ScriptConnectorParser.DeleteMessageStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#deleteMessageStmt.
    def exitDeleteMessageStmt(self, ctx:ScriptConnectorParser.DeleteMessageStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#bulkDeleteMessagesStmt.
    def enterBulkDeleteMessagesStmt(self, ctx:ScriptConnectorParser.BulkDeleteMessagesStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#bulkDeleteMessagesStmt.
    def exitBulkDeleteMessagesStmt(self, ctx:ScriptConnectorParser.BulkDeleteMessagesStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#setVoiceStateStmt.
    def enterSetVoiceStateStmt(self, ctx:ScriptConnectorParser.SetVoiceStateStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#setVoiceStateStmt.
    def exitSetVoiceStateStmt(self, ctx:ScriptConnectorParser.SetVoiceStateStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#createThreadStmt.
    def enterCreateThreadStmt(self, ctx:ScriptConnectorParser.CreateThreadStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#createThreadStmt.
    def exitCreateThreadStmt(self, ctx:ScriptConnectorParser.CreateThreadStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#setThreadArchivedStmt.
    def enterSetThreadArchivedStmt(self, ctx:ScriptConnectorParser.SetThreadArchivedStmtContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#setThreadArchivedStmt.
    def exitSetThreadArchivedStmt(self, ctx:ScriptConnectorParser.SetThreadArchivedStmtContext):
        pass


    # Enter a parse tree produced by ScriptConnectorParser#duration.
    def enterDuration(self, ctx:ScriptConnectorParser.DurationContext):
        pass

    # Exit a parse tree produced by ScriptConnectorParser#duration.
    def exitDuration(self, ctx:ScriptConnectorParser.DurationContext):
        pass



del ScriptConnectorParser