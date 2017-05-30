/*------------------------------------------------------------------------
  File        : activate.p
  Purpose     : Set the user for the current request, unless the requests
                are from Tomcat to HybridRealm.

  Syntax      :

  Description :

  Author(s)   : Chris
  Created     :
  Notes       :
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

DEFINE VARIABLE hCP        AS HANDLE    NO-UNDO.
DEFINE VARIABLE cPropName  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPropNames AS CHARACTER NO-UNDO.
DEFINE VARIABLE i          AS INTEGER   NO-UNDO.
DEFINE VARIABLE iNumProps  AS INTEGER   NO-UNDO.
DEFINE VARIABLE lDebug     AS LOGICAL   NO-UNDO INITIAL TRUE.

IF lDebug THEN
DO:
  MESSAGE SESSION:CURRENT-REQUEST-INFO:ProcedureName.
END.

hCP = SESSION:CURRENT-REQUEST-INFO:GetClientPrincipal().

IF VALID-HANDLE(hCP) AND hCP:DOMAIN-NAME <> "OESPA" THEN
DO:
  // Only log details or set the DB user if the requests are not to
  // HybridRealm.

  IF lDebug THEN
  DO:
    MESSAGE SUBSTITUTE("USER-ID: &1 Qualified user id: &2 Roles: &3 domain-name: &4 Property names: &5",
                        hCP:USER-ID,
                        hCP:QUALIFIED-USER-ID,
                        hCP:ROLES,
                        hCP:DOMAIN-NAME,
                        hCP:LIST-PROPERTY-NAMES()).

    ASSIGN cPropNames = hCP:LIST-PROPERTY-NAMES()
           iNumProps  = NUM-ENTRIES(cPropNames).

    DO i = 1 TO iNumProps:
      cPropName = ENTRY(i, cPropNames).
      MESSAGE SUBSTITUTE("Property: &1 Value: &2", cPropName, hCP:GET-PROPERTY(cPropName)).
    END.
  END.

  SET-DB-CLIENT(hCP).
END.
ELSE
DO:
  // MESSAGE "No CP provided".
END.