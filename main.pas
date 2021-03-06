//-->>Autor: L.I. Samuel Muñoz Chavez desarrollador de Facturación Moderna.
//-->>Última revisión 04/10/2012
//-->>Objetos necesarios para la implementación:  IdBase64Decoder del proyecto Indy Misc 
unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,IdCoder3To4,id3To4Coder1, IdBaseComponent, IdCoder,  msxml, msxmldom,  xmldom,  XMLIntf, XMLDoc;

type
  TForm1 = class(TForm)
    btnCancelar: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    GroupBox2: TGroupBox;
    txtFolioFiscal: TEdit;
    Label2: TLabel;
    btnTimbrar: TButton;
    txtLayout: TEdit;
    IdBase64Decoder1: TIdBase64Decoder;
    procedure btnCancelarClick(Sender: TObject);
    procedure btnTimbrarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses ComObj;

procedure TForm1.btnCancelarClick(Sender: TObject);
const READYSTATE_UNINITIALIZED = 0; // Default initialisation state.
const READYSTATE_LOADING = 1; // Object is currently loading data.
const READYSTATE_LOADED = 2; // Object has been initialised.
const READYSTATE_INTERACTIVE = 3; // User can interact with the object but loading has not yet finished.
const READYSTATE_COMPLETE = 4; // All of the object's data has been loaded.
var
    XMLHTTPCancelarCFDI,xmldoc : OleVariant;
    soapResponse,rfc,passwordUser,userId,UUID,mensajeCancelacion,codigoCancelacion:string;
begin
    //-->>A continuación se definen las credenciales de acceso al Web Service, en cuanto se active su servicio deberá cambiar esta información por sus claves de acceso en modo productivo
    rfc:='ESI920427886';
    passwordUser:='b9ec2afa3361a59af4b4d102d3f704eabdf097d4';
    userId:='UsuarioPruebasWS';
    UUID:= txtFolioFiscal.Text; //-->> Folio fiscal(uuid) a cancelar
    XMLHTTPCancelarCFDI := CreateOleObject('Microsoft.XMLHTTP'); //-->>Objeto encargado de realizar las peticiones http al web service de Facturación Moderna
    xmldoc := CreateOleObject('Msxml2.DOMDocument.3.0');

    XMLHTTPCancelarCFDI.Open('POST', 'https://t2demo.facturacionmoderna.com/timbrado/soap');
    XMLHTTPCancelarCFDI.setRequestHeader('Content-Type', 'text/xml; charset=utf-8');
    XMLHTTPCancelarCFDI.setRequestHeader('SOAPAction', 'https://t2demo.facturacionmoderna.com/timbrado/soap');  //-->>Dirección del web service

    XMLHTTPCancelarCFDI.send('<?xml version="1.0" encoding="UTF-8"?> <env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:ns1="https://t1demo.facturacionmoderna.com/timbrado/soap" xmlns:xsd="http://www.w3.org/2001/XMLSchema"'+
    ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:enc="http://www.w3.org/2003/05/soap-encoding"><env:Body><ns1:requestCancelarCFDI env:encodingStyle="http://www.w3.org/2003/05/soap-encoding">'+
    '<param0 xsi:type="enc:Struct"><CancelarCFDI xsi:type="enc:Struct"><UUID xsi:type="xsd:string">'+UUID+'</UUID></CancelarCFDI><UserPass xsi:type="xsd:string">'+passwordUser+'</UserPass>'+
    '<UserID xsi:type="xsd:string">'+userId+'</UserID><emisorRFC xsi:type="xsd:string">'+rfc+'</emisorRFC></param0></ns1:requestCancelarCFDI></env:Body></env:Envelope>');
    while (XMLHTTPCancelarCFDI.readyState <>  READYSTATE_COMPLETE) do
        Application.ProcessMessages;
    soapResponse := XMLHTTPCancelarCFDI.responseText;  //-->>Respuesta del Web Service

    if(xmldoc.loadXML(soapResponse)) then  //-->>Creamos un objeto capas de recorrer el xml de respuesta del servidor para mayor flexibilidad.
        begin
            If (xmldoc.getElementsByTagName('env:Fault').length >= 1) Then //-->> Si nos retorna un error el WS (Soap Fault) lo visualizamos
                begin
                showMessage(xmldoc.getElementsByTagName('env:Text').Item(0).Text);
                end
            else
                begin
                    mensajeCancelacion := xmldoc.getElementsByTagName('Message').Item(0).Text;
                    codigoCancelacion := xmldoc.getElementsByTagName('Code').Item(0).Text;
                    showMessage('[' + codigoCancelacion + ']' + mensajeCancelacion); //-->>Mensaje retornado por el WS
                end
        end
    else
        showMessage('Ha ocurrido un error!');
end;

procedure TForm1.btnTimbrarClick(Sender: TObject);
const READYSTATE_UNINITIALIZED = 0; // Default initialisation state.
const READYSTATE_LOADING = 1; // Object is currently loading data.
const READYSTATE_LOADED = 2; // Object has been initialised.
const READYSTATE_INTERACTIVE = 3; // User can interact with the object but loading has not yet finished.
const READYSTATE_COMPLETE = 4; // All of the object's data has been loaded.
var
    XMLHTTPTimbrarCFDI,xmldoc : OleVariant;
    layoutBase64,soapResponse,rfc,passwordUser,userId,UUID,rutaLayout,responseServer,nameCFDI:string;
    CFDIBase64,PDFBase64,CFDIXML,PDFString :WideString;
    F: TFileStream;
    F2:TextFile;
    s: String;
    TIdBase64Decoder : tid3To4Coder1;

      MSDOMDocument: IXMLDOMDocument;
      cfdiXmlDoc: IXMLDomDocument;
      node, rootnode,    xmlNode: IxmlDomNode;
      nodeList: IxmlDomNodeList;

begin
    rfc:='ESI920427886';
    passwordUser:='b9ec2afa3361a59af4b4d102d3f704eabdf097d4';
    userId:='UsuarioPruebasWS';
    UUID:= txtFolioFiscal.Text;
    XMLHTTPTimbrarCFDI := CreateOleObject('Microsoft.XMLHTTP'); //-->> Objeto encargado de realizar las peticiones http al web service de Facturación Moderna

    rutaLayout := txtLayout.Text ;
    F := TFileStream.Create( rutaLayout, fmOpenRead ); //-->>Lectura del layout contenedor del comprobante
    SetLength(s,F.Size);
    F.Read( s[1], F.Size );
    F.Free;
    layoutBase64:=Base64Encode(S);  //-->>Transformación del Layout a formato base64
    XMLHTTPTimbrarCFDI.Open('POST', 'https://t2demo.facturacionmoderna.com/timbrado/soap');
    XMLHTTPTimbrarCFDI.setRequestHeader('Content-Type', 'text/xml; charset=utf-8');
    XMLHTTPTimbrarCFDI.setRequestHeader('SOAPAction', 'https://t2demo.facturacionmoderna.com/timbrado/soap');  //-->>Dirección del web service
    XMLHTTPTimbrarCFDI.send('<?xml version="1.0" encoding="UTF-8"?><env:Envelope xmlns:env="http://www.w3.org/2003/05/soap-envelope" xmlns:ns1="https://t2demo.facturacionmoderna.com/timbrado/soap"'+
    ' xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:enc="http://www.w3.org/2003/05/soap-encoding"><env:Body><ns1:requestTimbrarCFDI env:encodingStyle="http://www.w3.org/2003/05/soap-encoding">'+
    '<param0 xsi:type="enc:Struct"><UserPass xsi:type="xsd:string">'+passwordUser+'</UserPass><UserID xsi:type="xsd:string">'+userId+'</UserID><emisorRFC xsi:type="xsd:string">'+rfc+'</emisorRFC>'+
    '<text2CFDI xsi:type="xsd:string">'+layoutBase64+'</text2CFDI></param0></ns1:requestTimbrarCFDI></env:Body></env:Envelope>');
    while (XMLHTTPTimbrarCFDI.readyState <>  READYSTATE_COMPLETE) do
        Application.ProcessMessages;
    soapResponse := XMLHTTPTimbrarCFDI.responseText;  //-->>Respuesta del web service
    xmldoc := CreateOleObject('Msxml2.DOMDocument.3.0'); //-->>Creamos un objeto capaz de acceder a los nodos de la respuesta en formato XML para mayor flexibilidad
    if(xmldoc.loadXML(soapResponse)) then
        begin
            If (xmldoc.getElementsByTagName('env:Fault').length >= 1) Then
                begin
                showMessage(xmldoc.getElementsByTagName('env:Text').Item(0).Text);
                end
            else
                begin
                    CFDIBase64 := xmldoc.getElementsByTagName('xml').Item(0).Text; //-->> En caso de éxito obtenemos el nodo xml contenedor del CFDI
                    PDFBase64 := xmldoc.getElementsByTagName('pdf').Item(0).Text;  //-->> Obtenemos la representación impresa del CFDI en formato PDF
                    IdBase64Decoder1.Reset();
                    IdBase64Decoder1.AddCRLF:=false;
                    IdBase64Decoder1.AutoCompleteInput := True;
                    CFDIXML := IdBase64Decoder1.CodeString(CFDIBase64);
                    Delete(CFDIXML,1,2);
                    cfdiXmlDoc:= CoDOMDocument.create;
                    If (cfdiXmlDoc.loadXML(CFDIXML)) Then
                    begin
                        xmlNode := cfdiXmlDoc.documentElement;
                        node:=cfdiXmlDoc.documentElement.getElementsByTagName('tfd:TimbreFiscalDigital').item[0];
                        UUID := node.attributes.getNamedItem('UUID').Text; //-->> A manera de ejemplo se almacena el XML y PDF con el folio fiscal(UUID) contenido en el xml
                        nameCFDI := UUID ;
                        F := TFileStream.Create( 'C:\'+nameCFDI+'.xml', fmCreate ); //-->> Almacenamiento del CFDI en formato xml en C:\
                        s := CFDIXML;
                        F.Write( s[1], Length( s ) );
                        F.Free;

                        IdBase64Decoder1.Reset();
                        IdBase64Decoder1.AddCRLF:=false;
                        IdBase64Decoder1.AutoCompleteInput := True;
                        PDFString := IdBase64Decoder1.CodeString(PDFBase64);
                        Delete(PDFString,1,2);
                        F := TFileStream.Create( 'C:\'+nameCFDI+'.pdf', fmCreate ); //-->> Almacenamiento de la representación impresa del CFDI en formato pdf en C:\
                        s := PDFString;
                        F.Write( s[1], Length( s ) );
                        F.Free;
                        showMessage('CFDI en formato xml y pdf generados correctamente en C:\' + nameCFDI + '.xml|.pdf');
                    end
                    else
                    begin
                    showMessage('No se cargo el parametro');
                    end
                end
        end
    else
        showMessage('Ha ocurrido un error!');
end;

end.
