open Types
open Aws
type input = CreateAssociationRequest.t
type output = CreateAssociationResult.t
type error = Errors.t
let service = "ssm"
let to_http req =
  let uri =
    Uri.add_query_params (Uri.of_string "https://ssm.amazonaws.com")
      (List.append
         [("Version", ["2014-11-06"]); ("Action", ["CreateAssociation"])]
         (Util.drop_empty
            (Uri.query_of_encoded
               (Query.render (CreateAssociationRequest.to_query req))))) in
  (`POST, uri, [])
let of_http body =
  try
    let xml = Ezxmlm.from_string body in
    let resp = Xml.member "CreateAssociationResponse" (snd xml) in
    try
      Util.or_error (Util.option_bind resp CreateAssociationResult.parse)
        (let open Error in
           BadResponse
             {
               body;
               message =
                 "Could not find well formed CreateAssociationResult."
             })
    with
    | Xml.RequiredFieldMissing msg ->
        let open Error in
          `Error
            (BadResponse
               {
                 body;
                 message =
                   ("Error parsing CreateAssociationResult - missing field in body or children: "
                      ^ msg)
               })
  with
  | Failure msg ->
      `Error
        (let open Error in
           BadResponse { body; message = ("Error parsing xml: " ^ msg) })
let parse_error code err =
  let errors =
    [Errors.InvalidInstanceId;
    Errors.InvalidDocument;
    Errors.InternalServerError;
    Errors.AssociationLimitExceeded;
    Errors.AssociationAlreadyExists] @ Errors.common in
  match Errors.of_string err with
  | Some var ->
      if
        (List.mem var errors) &&
          ((match Errors.to_http_code var with
            | Some var -> var = code
            | None  -> true))
      then Some var
      else None
  | None  -> None