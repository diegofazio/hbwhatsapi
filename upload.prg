#define HB_VERSION_BITWIDTH  17
#define NULL 0
#define SESSION_PATH "c:\harbour32-core\contrib\Whatsapp-api\"
#ifdef __PLATFORM__WINDOWS
#include "hbdyn.ch"
#else
#include "/usr/include/harbour/hbdyn.ch"
#endif


FUNCTION Main()

   LOCAL DATA, nStart, oResp := { => }
   PUBLIC pLib, hMySQL := 0, hConnection := 0, hMyRes := 0

   hValues := hb_jsonDecode( HW_PostPairs()[ "values" ] )

   if file( SESSION_PATH + "session.json")

      if hValues[ 'action' ] == 'QR'

         oResp[ 'status' ] := 'QR'
         oResp[ "data" ] := ''         
         HW_Write( hb_jsonEncode( oResp, .F. ) )
         RETURN

      endif

   else

      if hValues[ 'action' ] == 'QR'
         oResp[ 'status' ] := 'QR'
         IF File( SESSION_PATH + "qrcode.png")
            oResp[ "data" ] := "data:image/png;base64," + hb_base64Encode( hb_MemoRead( SESSION_PATH + "qrcode.png" ) )
         else
            oResp[ "data" ] := 'disconnected'         
         endif
         HW_Write( hb_jsonEncode( oResp, .F. ) )
         RETURN
      else
         IF !File( SESSION_PATH + "qrcode.png")         
            oResp[ 'status' ] := 'QR'
            oResp[ "data" ] := 'disconnected'         
            HW_Write( hb_jsonEncode( oResp, .F. ) )
            RETURN            
         endif
      endif

   endif

   pLib = hb_libLoad( hb_SysMySQL() )

   If( ValType( pLib ) != "P" )
      ? " (MySQL library not found)"
   ELSE

      hMySQL = mysql_init()
      If( hMySQL == 0 )
         ? "failed to initialize"
      ENDIF

   ENDIF

   IF hMySQL != 0
      hConnection := mysql_real_connect( "localhost", "harbour", "", "harbourdb", 3306 )
      If( hConnection != hMySQL )
         ? "Failed connection"
         ? mysql_error( hMySQL )
         mysql_exit()
         return
      ENDIF
   ENDIF

   IF hValues[ 'action' ] == 'getmsg'
      oResp[ 'status' ] := 'MSGREC'
      IF hConnection != 0
         cQuery :=  "SELECT * FROM whatsapp_in WHERE status = 0 LIMIT 1"
         nRetVal = mysql_query( hConnection, cQuery )
         IF nRetVal == 0
            hMyRes = mysql_store_result( hConnection )
            IF hMyRes != 0
               aData := mysql_fetchAll( hMyRes )
               oResp[ "data" ] = iif( empty( aData ), '', aData ) 
               if len(aData) != 0
                  nID := aData[ 1 ][ 1 ]
                  cQuery :=  "UPDATE whatsapp_in SET STATUS = 1 WHERE ID = " + valtochar(nID)
                  nRetVal = mysql_query( hConnection, cQuery )
               endif
               HW_Write( hb_jsonEncode( oResp, .F. ) )
               mysql_exit()                  
               return
            endif
         endif
      endif
      oResp[ "data" ] = ''
   endif

      


   IF hValues[ 'action' ] == 'sendmsg'

      nStart := hb_At( "base64,", hValues[ 'data' ] )

      IF ( nStart != 0 )
         DATA := SubStr( hValues[ 'data' ], nStart + 7 )
      ELSE
         DATA := hb_base64Encode( hValues[ 'data' ] )
      ENDIF
      IF hConnection != 0
         cQuery := "INSERT INTO `whatsapp_out` (`to`,`status`,`mimetype`,`data`,`caption`,`filename`,`timestamp`) VALUES ("
         cQuery += "'" + valtochar( hValues[ 'telephone' ] ) + "'" + ","
         cQuery += "0" + ","
         cQuery += "'" + hValues[ 'mimetype' ] + "'" + ","
         cQuery += "'" + DATA + "'" + ","
         cQuery += "'" + hValues[ 'caption' ] + "'" + ","
         cQuery += "'" + hValues[ 'filename' ] + "'" + ","
         cQuery += valtochar( hValues[ 'timestamp' ] )
         cQuery += ")"
         nRetVal = mysql_query( hConnection, cQuery )
         oResp[ 'status' ] := 'MSGOK'
         IF nRetVal == 0
            oResp[ "data" ] := 'OK'
         ELSE
            oResp[ "data" ] := 'ERROR'
         ENDIF

         HW_Write( hb_jsonEncode( oResp, .F. ) )
         mysql_exit()                  
         return
      ENDIF

   endif


RETURN


function mysql_fetchAll( hRes )

      LOCAL oRs
      LOCAL aData := {}
      
      
      WHILE ( !empty( oRs := mysql_fetch( hRes ) ) )
      
         Aadd( aData, oRs )
            
      END
     
RETURN aData

function mysql_fetch( hRes ) 

	LOCAL hRow
	LOCAL aReg
	LOCAL m, f
	
	if ( hRow := mysql_fetch_row( hRes ) ) != 0	
	
		aReg 	:= array( 7 )		
	
      for m = 1 to 7
         aReg[ m ] := PtrToStr( hRow, m - 1 ) 
      next				
		
	endif

RETURN aReg



function mysql_exit()

   IF hMyRes != 0
      mysql_free_result( hMyRes )
   ENDIF

   IF hMySQL != 0
      mysql_close( hMySQL )
   ENDIF

   IF ValType( pLib ) == "P"
      hb_libFree( pLib )
   ENDIF

return



// ----------------------------------------------------------------//

FUNCTION mysql_init()

RETURN hb_DynCall( { "mysql_init", pLib, hb_bitOr( hb_SysLong(), ;
      hb_SysCallConv() ) }, NULL )

// ----------------------------------------------------------------//

FUNCTION mysql_close( hMySQL )

RETURN hb_DynCall( { "mysql_close", pLib, ;
      hb_SysCallConv(), hb_SysLong() }, hMySQL )

// ----------------------------------------------------------------//

FUNCTION mysql_real_connect( cServer, cUserName, cPassword, cDataBaseName, nPort )

   IF nPort == nil
      nPort = 3306
   ENDIF

RETURN hb_DynCall( { "mysql_real_connect", pLib, hb_bitOr( hb_SysLong(), ;
      hb_SysCallConv() ), hb_SysLong(), ;
      HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CTYPE_CHAR_PTR, HB_DYN_CTYPE_CHAR_PTR, ;
      HB_DYN_CTYPE_LONG, HB_DYN_CTYPE_LONG, HB_DYN_CTYPE_LONG }, ;
      hMySQL, cServer, cUserName, cPassword, cDataBaseName, nPort, 0, 0 )

// ----------------------------------------------------------------//

FUNCTION mysql_query( hConnect, cQuery )

RETURN hb_DynCall( { "mysql_query", pLib, hb_bitOr( HB_DYN_CTYPE_INT, ;
      hb_SysCallConv() ), hb_SysLong(), HB_DYN_CTYPE_CHAR_PTR }, ;
      hConnect, cQuery )

// ----------------------------------------------------------------//

FUNCTION mysql_use_result( hMySQL )

RETURN hb_DynCall( { "mysql_use_result", pLib, hb_bitOr( hb_SysLong(), ;
      hb_SysCallConv() ), hb_SysLong() }, hMySQL )

// ----------------------------------------------------------------//

FUNCTION mysql_store_result( hMySQL )

RETURN hb_DynCall( { "mysql_store_result", pLib, hb_bitOr( hb_SysLong(), ;
      hb_SysCallConv() ), hb_SysLong() }, hMySQL )

// ----------------------------------------------------------------//

FUNCTION mysql_free_result( hMyRes )

RETURN hb_DynCall( { "mysql_free_result", pLib, ;
      hb_SysCallConv(), hb_SysLong() }, hMyRes )

// ----------------------------------------------------------------//

FUNCTION mysql_fetch_row( hMyRes )

RETURN hb_DynCall( { "mysql_fetch_row", pLib, hb_bitOr( hb_SysLong(), ;
      hb_SysCallConv() ), hb_SysLong() }, hMyRes )

// ----------------------------------------------------------------//

FUNCTION mysql_num_rows( hMyRes )

RETURN hb_DynCall( { "mysql_num_rows", pLib, hb_bitOr( hb_SysLong(), ;
      hb_SysCallConv() ), hb_SysLong() }, hMyRes )

// ----------------------------------------------------------------//

FUNCTION mysql_num_fields( hMyRes )

RETURN hb_DynCall( { "mysql_num_fields", pLib, hb_bitOr( HB_DYN_CTYPE_LONG_UNSIGNED, ;
      hb_SysCallConv() ), hb_SysLong() }, hMyRes )

// ----------------------------------------------------------------//

FUNCTION mysql_fetch_field( hMyRes )

RETURN hb_DynCall( { "mysql_fetch_field", pLib, hb_bitOr( hb_SysLong(), ;
      hb_SysCallConv() ), hb_SysLong() }, hMyRes )

// ----------------------------------------------------------------//

FUNCTION mysql_get_server_info( hMySQL )

RETURN hb_DynCall( { "mysql_get_server_info", pLib, hb_bitOr( HB_DYN_CTYPE_CHAR_PTR, ;
      hb_SysCallConv() ), hb_SysLong() }, hMySql )

// ----------------------------------------------------------------//

FUNCTION mysql_error( hMySQL )

RETURN hb_DynCall( { "mysql_error", pLib, hb_bitOr( HB_DYN_CTYPE_CHAR_PTR, ;
      hb_SysCallConv() ), hb_SysLong() }, hMySql )

// ----------------------------------------------------------------//

FUNCTION hb_SysLong()

RETURN If( hb_osIs64bit(), HB_DYN_CTYPE_LLONG_UNSIGNED, HB_DYN_CTYPE_LONG_UNSIGNED )

// ----------------------------------------------------------------//

FUNCTION hb_SysCallConv()

RETURN If( ! "Windows" $ OS(), HB_DYN_CALLCONV_CDECL, HB_DYN_CALLCONV_STDCALL )

// ----------------------------------------------------------------//

FUNCTION hb_SysMySQL()

   LOCAL cLibName

   IF ! "Windows" $ OS()
      IF "Darwin" $ OS()
         cLibName = "/usr/local/Cellar/mysql/8.0.16/lib/libmysqlclient.dylib"
      ELSE
         cLibName = If( hb_Version( HB_VERSION_BITWIDTH ) == 64, ;
            "/usr/lib/x86_64-linux-gnu/libmariadb.so.3", ; // libmysqlclient.so.20 for mariaDB
            "/usr/lib/x86-linux-gnu/libmariadbclient.so" )
      ENDIF
   ELSE
      cLibName = If( hb_Version( HB_VERSION_BITWIDTH ) == 64, ;
         "c:/xampp/apache/bin/libmariadb.dll", ;
         "c:/xampp/apache/bin/libmysql.dll" )
   ENDIF

RETURN cLibName
