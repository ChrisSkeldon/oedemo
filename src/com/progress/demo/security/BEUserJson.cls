/*------------------------------------------------------------------------
  File        : BEUserJson
  Purpose     : Provide access to user information needed as part of
                authenticating a user.
  Syntax      :
  Description :
  Author(s)   : Chris
  Created     :
  Notes       : Intended for demonstration purposes to primarily work
                with users stored in .json file
  ----------------------------------------------------------------------*/

BLOCK-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.AppError FROM PROPATH.
USING com.progress.demo.security.IAppUserProvider FROM PROPATH.

CLASS com.progress.demo.security.BEUserJson IMPLEMENTS IAppUserProvider :

  {com/progress/demo/security/dsAppUser.i}

  // Path to the file containing users.
  DEFINE VARIABLE cPath           AS CHARACTER NO-UNDO.

  // TRUE if the users are being stored in a database.
  DEFINE VARIABLE lUserSourceIsDB AS LOGICAL   NO-UNDO.

  /*------------------------------------------------------------------------------
   Purpose: Return the value for a attribute associated with a user.

   Notes: Three logical attribute are supported, 'AccountLocked',
          'AccountDisabled' and 'AccountExpired'. The only character attribute
          supported is 'Roles', which is a comma-separated list of the roles
          assigned to the user.

          If the user identifier passed in does not identify a user an
          AppError is thrown.

   @param piUserNumber Unique identifier for a user
   @param pcPropertyName Name of the attribute to return a value for.
   @return Value of the attribute or, if the attribute is not found, an empty
           string.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC CHARACTER FetchAttribute( INPUT piUserNumber AS INTEGER,
                                          INPUT pcPropertyName AS CHARACTER ):

    DEFINE VARIABLE cAttrValue AS CHARACTER NO-UNDO.

    FIND FIRST ttAppUser WHERE ttAppUser.UserNumber = piUserNumber NO-ERROR.

    IF NOT AVAILABLE ttAppUser THEN
    DO:
      UNDO, THROW NEW AppError(SUBSTITUTE("FetchProperty(): No user found for number &1",
                                          piUserNumber), 1).
    END.

    CASE pcPropertyName:

      WHEN "ATTR_ENABLED" THEN
      DO:
        cAttrValue = STRING(NOT ttAppUser.IsDisabled).
      END.

      WHEN "ATTR_EXPIRED" THEN
      DO:
        cAttrValue = STRING(ttAppUser.isExpired).
      END.

      WHEN "ATTR_LOCK_TIME_REM" THEN
      DO:
        // Intoduced in Rollbase 4.2: time remaining for account to get unlocked
        cAttrValue = "".
      END.

      WHEN "ATTR_LOCKED" THEN
      DO:
        cAttrValue = STRING(ttAppUser.IsLocked).
      END.

      WHEN "ATTR_ROLES" THEN
      DO:
        cAttrValue = ttAppUser.UserRoles.
      END.

      WHEN "ATTR_PROPERTIES" THEN
      DO:
        cAttrValue = '~{"dept": "PS", "service": "long"}'.
      END.

    END CASE.

    RETURN cAttrValue.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Read the system's users.

   @param dsAppUser ProDataSet containing the users.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID FetchUsers( OUTPUT DATASET dsAppUser ):


  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Is passed in a user's login name and returns the unique integer
            identifier for that user.

   Notes: If the login name includes a @ symbol it is assumed to be the
          separator between the log in and domain name. If not present the
          user is just looked up on their on longin name.

   @param User's login name.
   @return The unique identifier for a user or -1 if the login name does not
           match a current user.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC INTEGER FetchUserNumber( INPUT pcLoginName AS CHARACTER ):

    IF NUM-ENTRIES(pcLoginName, "@") > 1 THEN
    DO:
      FIND FIRST ttAppUser WHERE ttAppUser.AppUserid = ENTRY(1, pcLoginName, "@") AND
                                 ttAppUser.DomainName = ENTRY(2, pcLoginName, "@") NO-ERROR.
    END.
    ELSE
    DO:
      FIND FIRST ttAppUser WHERE ttAppUser.AppUserid = pcLoginName AND
                                 ttAppUser.DomainName = "" NO-ERROR.
    END.

    RETURN IF AVAILABLE ttAppUser THEN ttAppUser.UserNumber ELSE -1.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Is passed the unique identifier for a user and a related password.
            Verifies that the password passed in is correct for that user.

   Notes: If the user identifier passed in does not identify a user an AppError
          is thrown.

   @param piUserNumber Unique identifier for a user.
   @param pcUserPassword User's password.
   @return TRUE if the user's password is valid and FALSE otherwise.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL IsPasswordValid( INPUT piUserNumber AS INTEGER,
                                         INPUT pcUserPassword AS CHARACTER ):

    FIND FIRST ttAppUser WHERE ttAppUser.UserNumber = piUserNumber NO-ERROR.

    IF NOT AVAILABLE ttAppUser THEN
    DO:
      UNDO, THROW NEW AppError(SUBSTITUTE("IsPasswordValid(): No user found for number &1",
                                          piUserNumber), 1).
    END.

    RETURN IF ttAppUser.Password = pcUserPassword THEN TRUE ELSE FALSE.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Set the password for a user.
   Notes:
   @param piUserNumber Unique identifier for a user.
   @param pcUserPassword User's new password.
   @return TRUE if the user's password is set and FALSE otherwise.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL SetPassword( INPUT piUserNumber AS INTEGER,
                                     INPUT pcUserPassword AS CHARACTER ):

    FIND FIRST ttAppUser WHERE ttAppUser.UserNumber = piUserNumber NO-ERROR.

    IF NOT AVAILABLE ttAppUser THEN
    DO:
      UNDO, THROW NEW AppError(SUBSTITUTE("SetPassword(): No user found for number &1",
                                          piUserNumber), 1).
    END.

    ttAppUser.Password = pcUserPassword.

    IF NOT lUserSourceIsDB THEN
    DO:
      DATASET dsAppUser:WRITE-JSON("FILE", cPath, TRUE).
    END.

    RETURN TRUE.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Sets where this class should get its users from.

   Notes: If users are loaded from a file, file must be in json format and
          on the PROPATH.

   @param pcUserSource Should be 'db' if the users are stored on the database or
          the name of the file to load users from.
   @return Number of users loaded from file or found in the database.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC INT64 SetUserSource( INPUT pcUserSource AS CHARACTER ):

    DEFINE VARIABLE iCnt  AS INT64 NO-UNDO.

    IF pcUserSource = "db" THEN
    DO:
      ASSIGN lUserSourceIsDB = TRUE
             cPath = ?.
    END.
    ELSE
    DO:
      ASSIGN cPath = SEARCH(pcUserSource)
             lUserSourceIsDB = FALSE.

      IF cPath = ? THEN
      DO:
        UNDO, THROW NEW AppError(SUBSTITUTE("Unable to find users file: &1", pcUserSource), 1).
      END.

      DATASET dsAppUser:READ-JSON("FILE", cPath, "EMPTY").

      FOR EACH ttAppUser:
        iCnt = iCnt + 1.
      END.

    END.

    RETURN iCnt.

    CATCH e AS Progress.Lang.Error :
      MESSAGE e:GetMessage(1) e:CallStack.
      UNDO, THROW e.
    END CATCH.

  END METHOD.

END CLASS.