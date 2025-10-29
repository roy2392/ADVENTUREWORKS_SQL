import json
import urllib.request
import urllib.parse
import base64
import logging
import xml.etree.ElementTree as ET

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

SAP_HOST = "aws-saptfc-demosystems-sapsbx.awsforsap.sap.aws.dev"
SAP_USER = "AWSDEMO"
SAP_PASSWORD = "Awsdemo12345@"

def make_sap_request(url, timeout=30):
    """Make HTTP request to SAP OData service"""
    try:
        credentials = f"{SAP_USER}:{SAP_PASSWORD}"
        encoded_credentials = base64.b64encode(credentials.encode()).decode()
        
        req = urllib.request.Request(url)
        req.add_header('Authorization', f'Basic {encoded_credentials}')
        req.add_header('Accept', 'application/xml')
        
        with urllib.request.urlopen(req, timeout=timeout) as response:
            if response.status == 200:
                return {"status": "success", "data": response.read().decode('utf-8')}
            else:
                return {"status": "error", "message": f"HTTP {response.status}"}
                
    except urllib.error.HTTPError as e:
        error_body = ""
        try:
            error_body = e.read().decode('utf-8')
        except:
            pass
        return {"status": "error", "message": f"HTTP Error {e.code}: {e.reason}", "details": error_body}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def parse_xml_entries(xml_content):
    """Parse SAP XML response to extract data entries"""
    try:
        root = ET.fromstring(xml_content)
        namespaces = {
            'atom': 'http://www.w3.org/2005/Atom',
            'd': 'http://schemas.microsoft.com/ado/2007/08/dataservices',
            'm': 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata'
        }
        
        entries = []
        for entry in root.findall('.//atom:entry', namespaces):
            properties = entry.find('.//m:properties', namespaces)
            if properties is not None:
                data = {}
                for prop in properties:
                    tag_name = prop.tag.split('}')[-1]
                    data[tag_name] = prop.text if prop.text else ""
                entries.append(data)
        
        return {"entries": entries, "total_count": len(entries)}
    except Exception as e:
        return {"parse_error": str(e), "raw_xml_preview": xml_content[:500]}

def get_purchase_order(po_number):
    """Get purchase order header data"""
    filter_param = urllib.parse.quote(f"PurchaseOrder eq '{po_number}'")
    url = f"https://{SAP_HOST}/sap/opu/odata/sap/C_PURCHASEORDER_FS_SRV/I_PurchaseOrder?$filter={filter_param}&$format=xml"
    
    result = make_sap_request(url)
    if result["status"] == "success":
        parsed = parse_xml_entries(result["data"])
        return {"status": "success", "data": parsed, "url": url}
    return result

def get_purchase_order_items(po_number):
    """Get purchase order line items"""
    filter_param = urllib.parse.quote(f"PurchaseOrder eq '{po_number}'")
    url = f"https://{SAP_HOST}/sap/opu/odata/sap/C_PURCHASEORDER_FS_SRV/I_PurchaseOrderItem?$filter={filter_param}&$format=xml"
    
    result = make_sap_request(url)
    if result["status"] == "success":
        parsed = parse_xml_entries(result["data"])
        return {"status": "success", "data": parsed, "url": url}
    return result

def get_complete_po_data(po_number):
    """Get complete purchase order data including header and items"""
    results = {
        "purchase_order": po_number,
        "header": get_purchase_order(po_number),
        "items": get_purchase_order_items(po_number)
    }
    
    # Calculate totals for finance closure decision
    total_value = 0
    total_quantity = 0
    
    if results["items"]["status"] == "success":
        for item in results["items"]["data"]["entries"]:
            try:
                net_amount = float(item.get("NetAmount", 0) or 0)
                quantity = float(item.get("OrderQuantity", 0) or 0)
                total_value += net_amount
                total_quantity += quantity
            except (ValueError, TypeError):
                continue
    
    summary = {
        "po_number": po_number,
        "header_found": results["header"]["status"] == "success" and len(results["header"].get("data", {}).get("entries", [])) > 0,
        "items_count": len(results["items"].get("data", {}).get("entries", [])) if results["items"]["status"] == "success" else 0,
        "total_value": total_value,
        "total_quantity": total_quantity,
        "can_close_po": total_value > 0 and total_quantity > 0
    }
    
    results["summary"] = summary
    return results

def extract_po_number_from_bedrock_event(event):
    """Extract PO number from Bedrock Agent event structure"""
    po_number = None
    
    # Check requestBody for Bedrock Agent format
    if event.get("requestBody") and event["requestBody"].get("content"):
        content = event["requestBody"]["content"]
        if content.get("application/json") and content["application/json"].get("properties"):
            for prop in content["application/json"]["properties"]:
                if prop.get("name") == "po_number":
                    po_number = prop.get("value")
                    break
    
    # Extract from inputText if not found in properties
    if not po_number and event.get("inputText"):
        input_text = event["inputText"]
        # Look for PO number patterns in the input text
        import re
        po_match = re.search(r'PO\s+(\d+)', input_text, re.IGNORECASE)
        if po_match:
            po_number = po_match.group(1)
    
    return po_number

def lambda_handler(event, context):
    print(json.dumps(event))
    """AWS Lambda handler for Bedrock Agent integration"""
    try:
        # Extract PO number from Bedrock Agent event
        po_number = extract_po_number_from_bedrock_event(event)
        
        # Default fallback
        if not po_number:
            po_number = "4500000520"
        
        # Get complete PO data
        result = get_complete_po_data(po_number)
        
        # Format response for Bedrock Agent
        response_body = {
            "TEXT": {
                "body": json.dumps(result, indent=2)
            }
        }
        
        bedrock_response = {
            "messageVersion": "1.0",
            "response": {
                "actionGroup": event.get("actionGroup", ""),
                "apiPath": event.get("apiPath", ""),
                "httpMethod": event.get("httpMethod", "POST"),
                "httpStatusCode": 200,
                "responseBody": response_body
            }
        }
        
        print(json.dumps(bedrock_response, indent=2))
        return bedrock_response
        
    except Exception as e:
        error_response = {
            "messageVersion": "1.0",
            "response": {
                "actionGroup": event.get("actionGroup", ""),
                "apiPath": event.get("apiPath", ""),
                "httpMethod": event.get("httpMethod", "POST"),
                "httpStatusCode": 500,
                "responseBody": {
                    "TEXT": {
                        "body": json.dumps({
                            "error": str(e),
                            "type": type(e).__name__
                        })
                    }
                }
            }
        }
        print(json.dumps(error_response, indent=2))
        return error_response
