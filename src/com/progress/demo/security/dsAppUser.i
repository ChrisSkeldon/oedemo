/*------------------------------------------------------------------------
  File        : dsAppUser.i
  Purpose     : ProDataSet for application users. 

  Syntax      :

  Description : 

  Author(s)   : Chris
  Created     : 
  Notes       :
  ----------------------------------------------------------------------*/

{com/progress/demo/security/ttAppUser.i {&*}}

DEFINE {&SCOPE} DATASET dsAppUser{&SUFFIX} {&REFERENCE-ONLY}
  FOR ttAppUser{&SUFFIX}.
