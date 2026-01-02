# Just loading from ClickOps for now:

#TMP:
data "aws_iam_role" "core-role" {
  name = "AllowLambda2WriteLogs2CloudWatchRWS3AndInvokeOtherFunctions"
}

#TMP:
data "aws_iam_role" "list-role" {
  name = "respond_with_listmd_as_json-role-5a3esndg"
}

#TMP:
data "aws_iam_role" "cleanup-role" {
  name = "AllowDownstreamLambda2DeletePlaylistS3"
}
