/*------------------------------------------------------------------------
  File        : HybridRealm
  Purpose     : OEBPM Hybrid Realm for Single Point of Authentication
  Syntax      :
  Description : Singleton class that implements IHybridRealm for use as
                a single point of authentication for OEBPM.
  Author(s)   : davec
  Created     : Tue Feb 26 10:41:36 EST 2013
  Notes       :
 ----------------------------------------------------------------------*/

ROUTINE-LEVEL ON ERROR UNDO, THROW.

USING Progress.Security.Realm.IHybridRealm FROM PROPATH.
USING com.progress.demo.security.IAppUserProvider FROM PROPATH.
USING com.progress.demo.security.Properties FROM PROPATH.

CLASS com.progress.demo.security.HybridRealm IMPLEMENTS IHybridRealm:

  DEFINE PUBLIC PROPERTY IAppUserProvider AS IAppUserProvider NO-UNDO
    PUBLIC GET. PUBLIC SET.

  DEFINE PRIVATE VARIABLE cUsersSource    AS CHARACTER NO-UNDO.
  DEFINE PRIVATE VARIABLE lOutputDebugMsg AS LOGICAL   NO-UNDO INITIAL TRUE.
  DEFINE PRIVATE VARIABLE passwd          AS CHARACTER NO-UNDO.
  DEFINE PRIVATE VARIABLE role            AS CHARACTER NO-UNDO.
  DEFINE PRIVATE VARIABLE lValidateClient AS LOGICAL   NO-UNDO.
  DEFINE PRIVATE VARIABLE spaProps        AS CLASS     Properties.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  CONSTRUCTOR PUBLIC HybridRealm (  ):

    DEFINE VARIABLE cPropsFile         AS CHARACTER            NO-UNDO INITIAL "demoauth.properties".
    DEFINE VARIABLE cUserProviderClass AS CHARACTER            NO-UNDO.
    DEFINE VARIABLE oProvider          AS Progress.Lang.Object NO-UNDO.

    SUPER ().

    ASSIGN spaProps = NEW Properties(cPropsFile)

           /* Will be used to validate the seal on the REST Adaptor's client-principal - see ValidateClient() */

           passwd = spaProps:GetCharacterProperty("Password", "")

           /* This must match the role in the REST Adaptor's client-principal - see ValidateClient() */

           role = spaProps:GetCharacterProperty("Role", "SpaClient")

           lOutputDebugMsg = spaProps:GetLogicalProperty("DebugMsg", ?)
           lValidateClient = spaProps:GetLogicalProperty("ValidateClientCP", TRUE)
           cUsersSource = spaProps:GetCharacterProperty("UsersSource", "users.json")
           cUserProviderClass = spaProps:GetCharacterProperty("UserProvider", "").

    oProvider = DYNAMIC-NEW cUserProviderClass().
    IAppUserProvider = CAST(oProvider, "IAppUserProvider").

    IAppUserProvider:SetUserSource(cUsersSource).

    IF lOutputDebugMsg THEN
    DO:
      MESSAGE "Loaded property file:" cPropsFile
              "   Password: "  passwd SKIP
              "   Role: " ROLE SKIP
              "   lValidateClient" lValidateClient SKIP
              "   DebugMsg:" lOutputDebugMsg SKIP
              "   UsersSource:" cUsersSource SKIP
              "   UserProvider:" cUserProviderClass.
    END.


    CATCH e AS Progress.Lang.Error :
      MESSAGE e:GetMessage(1) e:CallStack.
      UNDO, THROW e.
    END CATCH.

  END CONSTRUCTOR.


  /*------------------------------------------------------------------------------
   Purpose: Return an attribute for a user.
   Notes:
   @param piUserNum Number that uniquely identifies a user.
   @param pcAttrName Name of the attribute to get a value for.
   @Return The value of the requested attribute or the unknown value if the
           attribute cannot be found.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC CHARACTER GetAttribute( INPUT piUserNum AS INTEGER,
                                        INPUT pcAttrName AS CHARACTER ):

    DEFINE VARIABLE cAttrValue AS CHARACTER NO-UNDO INITIAL ?.

    IF THIS-OBJECT:ValidateClient() = FALSE THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Unauthorized client", 1).
    END.

    cAttrValue = IAppUserProvider:FetchAttribute(piUserNum, pcAttrName).

    writeDebugLog(SUBSTITUTE("GetAttribute, piUserNum: &1, pcAttrName: &2, cAttrValue: &3",
                             piUserNum, pcAttrName, cAttrValue)).

    RETURN cAttrValue.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Return an array of attributes that apply to the current user.
   Notes:
   @param piUserNum Identifier of the user.
   @return Character array of attribute names for the user passed in.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC CHARACTER EXTENT GetAttributeNames( INPUT piUserNum AS INTEGER ):

    DEFINE VARIABLE cAttrNames AS CHARACTER EXTENT NO-UNDO.

    UNDO, THROW NEW Progress.Lang.AppError("GetAttributeNames() is not implemented", 1).

   // RETURN cAttrNames.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC CHARACTER EXTENT GetUserNames(  ):

    DEFINE VARIABLE cUserNames AS CHARACTER EXTENT NO-UNDO.

    writeDebugLog("GetUserNames").

    IF THIS-OBJECT:ValidateClient() = FALSE THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Unauthorized client", 1).
    END.

    RETURN cUserNames.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC CHARACTER EXTENT GetUserNamesByQuery( INPUT queryString AS CHARACTER ):

    DEFINE VARIABLE cUserNames AS CHARACTER EXTENT NO-UNDO.

    writeDebugLog("GetUSerNamesByQuery: " + queryString).

    IF THIS-OBJECT:ValidateClient() = FALSE THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Unauthorized client", 1).
    END.

    RETURN cUserNames.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL RemoveAttribute( INPUT theUserId AS INTEGER,
                                         INPUT attrName AS CHARACTER ):

    DEFINE VARIABLE lSuccess AS LOGICAL NO-UNDO INITIAL TRUE.

    writeDebugLog(SUBSTITUTE("RemoveAttribute, theUserId: &1, attrName: &2",
                             theUserId, attrName)).

    IF THIS-OBJECT:ValidateClient() = FALSE THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Unauthorized client", 1).
    END.

    RETURN lSuccess.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: If being used with Rollbase and the 'Manages Password' option within
            Rollbase's OE Authentication configuration is set, this will be
            called to change a user's password.
   Notes:
   @param piUserId Unique identifier for a user.
   @param pcAttrName Name of the parameter to set, for example ATTR_PASSWORD.
   @param pcAttrValue Value to set pcAttrName to.
   @return TRUE if the appribute and FALSE otherwise.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL SetAttribute( INPUT piUserId AS INTEGER,
                                      INPUT pcAttrName AS CHARACTER,
                                      INPUT pcAttrValue AS CHARACTER ):

    DEFINE VARIABLE lSuccess AS LOGICAL NO-UNDO INITIAL TRUE.

    writeDebugLog(SUBSTITUTE("SetAttribute(), piUserId: &1, attrName: &2, attrValue: &3",
                             piUserId, pcAttrName, pcAttrValue)).

    IF THIS-OBJECT:ValidateClient() = FALSE THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Unauthorised client", 1).
    END.

    IF pcAttrName = "ATTR_PASSWORD" THEN
    DO:
      lSuccess = IAppUserProvider:SetPassword(piUserId, pcAttrValue).
    END.

    IF NOT lSuccess THEN
    DO:
      writeDebugLog(SUBSTITUTE("SetAttribute(), piUserId: &1, attrName: &2, attrValue: &3 FAILED",
                               piUserId, pcAttrName, pcAttrValue)).
    END.

    RETURN lSuccess.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Check that the PAS REST Adaptor is a valid client.
   Notes: This checks that:

     1. A client principal has been passed from the Adaptor
     2. It has a valid seal (need a password to verify this)
     3. The role it contains matches what we are expecting.

  @return TRUE if the CLIENT-PRINCIPAL in the request is valid and false
          otherwise.
  ------------------------------------------------------------------------------*/
  METHOD PROTECTED LOGICAL ValidateClient(  ):

    DEFINE VARIABLE result AS LOGICAL NO-UNDO INITIAL FALSE.
    DEFINE VARIABLE hCP    AS HANDLE  NO-UNDO.

    IF NOT lValidateClient THEN
    DO:
      RETURN TRUE.
    END.
/*    writeDebugLog("ValidateClient").*/

    hCP = SESSION:CURRENT-REQUEST-INFO:GetClientPrincipal().

    IF (hCP <> ?) THEN
    DO:
      result = hCP:VALIDATE-SEAL(passwd).

      IF RESULT = FALSE THEN
      DO:
        MESSAGE "ValidateClient() got FALSE from hCP:VALIDATE-SEAL()".
      END.
    END.
    ELSE
    DO:
      MESSAGE "No client-principal found by ValidateClient()".
    END.

    IF RESULT = TRUE THEN
    DO:
      IF hCP:ROLES <> role THEN
      DO:
        RESULT = FALSE.
        MESSAGE SUBSTITUTE("hCP:ROLES [&1] <> role [&2]", hCP:ROLES, role).
      END.
    END.

    RETURN result.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Validate the user's password.
   Notes:
   @param piUserNum Unique numberic identifier for a user.
   @param pcPassword The user's password.
   @return True if the password is valid and false otherwise.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL ValidatePassword( INPUT piUserNum AS INTEGER,
                                          INPUT pcPassword AS CHARACTER ):

    DEFINE VARIABLE lIsValid AS LOGICAL NO-UNDO INITIAL FALSE.

    writeDebugLog(SUBSTITUTE("ValidatePassword piUserNum: &1 password: &2",
                              piUserNum,
                              pcPassword)).

    IF NOT THIS-OBJECT:ValidateClient() THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Unauthorized client", 1).
    END.

    lIsValid = IAppUserProvider:IsPasswordValid(piUserNum, pcPassword).

    writeDebugLog(SUBSTITUTE("Password for piUserNum &1 i valid: &2",
                             piUserNum,
                             lIsValid)).
    RETURN lIsValid.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC LOGICAL ValidatePassword( INPUT piUserNum AS INTEGER,
                                          INPUT digest AS CHARACTER,
                                          INPUT nonce AS CHARACTER,
                                          INPUT timestamp AS CHARACTER ):

    DEFINE VARIABLE lSuccess AS LOGICAL     NO-UNDO INITIAL FALSE.
    DEFINE VARIABLE password AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE myDigest AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE df       AS CHARACTER   NO-UNDO.
    DEFINE VARIABLE remoteTS AS DATETIME-TZ NO-UNDO.
    DEFINE VARIABLE dif      AS INT64       NO-UNDO.
    DEFINE VARIABLE hash     AS RAW         NO-UNDO.

    writeDebugLog(SUBSTITUTE("ValidatePassword (four params) theUserId: &1", piUserNum)).

    IF THIS-OBJECT:ValidateClient() = FALSE THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Unauthorized client", 1).
    END.

    RETURN lSuccess.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Check that a username is valid.

   Notes: This is passed the userid and expects to have an integer returned that
          represents the user.

   @param pcUserName Id of the user, with domain if appropriate, to validate.
   @return Number that uniquely identifies the user or -1 if the user is not
           found.
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC INTEGER ValidateUser( INPUT pcUserName AS CHARACTER ):

    DEFINE VARIABLE iUserNum AS INTEGER NO-UNDO INITIAL -1.

    writeDebugLog(SUBSTITUTE("ValidateUser userName: &1", pcUserName)).

    IF THIS-OBJECT:ValidateClient() = FALSE THEN
    DO:
      UNDO, THROW NEW Progress.Lang.AppError("Unauthorized client", 1).
    END.

    iUserNum = IAppUserProvider:FetchUserNumber(pcUserName)
.
    writeDebugLog(SUBSTITUTE("ValidateUser pcUserName: &1 and got user number &2",
                             pcUserName, iUserNum)).

    RETURN iUserNum.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose: Write out a message if debug messaging is enabled.
   Notes:
   @param pcMsg Message to output.
  ------------------------------------------------------------------------------*/
  METHOD PRIVATE VOID writeDebugLog( INPUT pcMsg AS CHARACTER ):

    IF lOutputDebugMsg THEN
    DO:
      MESSAGE pcMsg "~n".
    END.

  END METHOD.

END CLASS.