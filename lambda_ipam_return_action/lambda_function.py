import boto3
import json
import logging
import os
import requests
import ipaddress
import urllib.parse
import pprint

from base64 import b64decode
from urllib.parse import parse_qs


ENCRYPTED_EXPECTED_TOKEN = os.environ['kmsEncryptedToken']
NETBOX_TOKEN = os.environ['NETBOX_TOKEN']

netbox_url = '<redacted>'
netbox_headers = {'Authorization': "Token {}".format(NETBOX_TOKEN)}


kms = boto3.client('kms')
expected_token = kms.decrypt(
    CiphertextBlob=b64decode(ENCRYPTED_EXPECTED_TOKEN),
    EncryptionContext={'LambdaFunctionName': os.environ['AWS_LAMBDA_FUNCTION_NAME']}
)['Plaintext'].decode('utf-8')

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def respond(err, res=None):
    return {
        'statusCode': '400' if err else '200',
        'body': err.message if err else json.dumps(res).encode('utf8'),
        'headers': {
            'Content-Type': 'application/json',
        },
    }


def netbox_return_prefixes(tag):
    ipam_api_call = requests.get(netbox_url+"/api/ipam/prefixes/?limit=0&tag="+tag, headers=netbox_headers, verify=False).json()
    return ipam_api_call.get('results')


def netbox_return_addresses(tag):
    ipam_api_call = requests.get(netbox_url+"/api/ipam/ip-addresses/?limit=0&tag="+tag, headers=netbox_headers, verify=False).json()
    return ipam_api_call.get('results')


def netbox_return_ranges(tag):
    ipam_api_call = requests.get(netbox_url+"/api/ipam/ip-ranges/?limit=0&tag="+tag, headers=netbox_headers, verify=False).json()
    return ipam_api_call.get('results')


def netbox_return_prefix_input(input):
    ipam_api_call = requests.get(netbox_url+"/api/ipam/prefixes/?limit=0&prefix="+input, headers=netbox_headers, verify=False).json()
    return ipam_api_call.get('results')


def netbox_return_address_input(input):
    ipam_api_call = requests.get(netbox_url+"/api/ipam/ip-addresses/?limit=0&address="+input, headers=netbox_headers, verify=False).json()
    return ipam_api_call.get('results')

def netbox_return_prefix_contains_input(input):
    ipam_api_call = requests.get(netbox_url+"/api/ipam/prefixes/?limit=0&contains="+input, headers=netbox_headers, verify=False).json()
    return ipam_api_call.get('results')

def send_ephemeral_message(response_url, data):
    ephemeral_headers = {'Content-Type': 'application/json'}
    # logger.info(response_url)

    return requests.post(response_url, headers=ephemeral_headers, json=data)


def action_get_public_nat(tag="public_egress"):
    public_nat_prefixes = netbox_return_prefixes(tag)
    public_nat_ranges = netbox_return_ranges(tag)
    public_nat_addresses = netbox_return_addresses(tag)

    ephemeral_response_text = ""
    for prefix in public_nat_prefixes:
        ephemeral_response_text += "Prefix --> "+str(prefix.get('prefix'))+" | Description --> "+str(prefix.get('description'))+"\n"
    for range in public_nat_ranges:
        ephemeral_response_text += "Range --> "+str(range.get('display'))+" | Description --> "+str(range.get('description'))+"\n"
    for address in public_nat_addresses:
        ephemeral_response_text += "Address --> "+str(address.get('address'))+" | Description --> "+str(address.get('description'))+"\n"

    return ephemeral_response_text


def action_get_trusted_user_subnet(tag="wireless_user_subnet"):
    trusted_user_prefixes = netbox_return_prefixes(tag)
    trusted_user_ranges = netbox_return_ranges(tag)
    trusted_user_addresses = netbox_return_addresses(tag)

    ephemeral_response_text = ""
    for prefix in trusted_user_prefixes:
        ephemeral_response_text += "Prefix --> "+str(prefix.get('prefix'))+" | Description --> "+str(prefix.get('description'))+"\n"
    for range in trusted_user_ranges:
        ephemeral_response_text += "Range --> "+str(range.get('display'))+" | Description --> "+str(range.get('description'))+"\n"
    for address in trusted_user_addresses:
        ephemeral_response_text += "Address --> "+str(address.get('address'))+" | Description --> "+str(address.get('description'))+"\n"

    return ephemeral_response_text


def action_get_tagged_subnet(tag):
    trusted_user_prefixes = netbox_return_prefixes(tag)
    trusted_user_ranges = netbox_return_ranges(tag)
    trusted_user_addresses = netbox_return_addresses(tag)

    ephemeral_response_text = ""
    for prefix in trusted_user_prefixes:
        ephemeral_response_text += "Prefix --> "+str(prefix.get('prefix'))+" | Description --> "+str(prefix.get('description'))+"\n"
    for range in trusted_user_ranges:
        ephemeral_response_text += "Range --> "+str(range.get('display'))+" | Description --> "+str(range.get('description'))+"\n"
    for address in trusted_user_addresses:
        ephemeral_response_text += "Address --> "+str(address.get('address'))+" | Description --> "+str(address.get('description'))+"\n"

    return ephemeral_response_text


def action_get_more_info(user_input):
    prefix_info = netbox_return_prefix_input(user_input)
    address_info = netbox_return_address_input(user_input)
    prefix_contains_info = netbox_return_prefix_contains_input(user_input)

    # logger.info(user_input)
    # logger.info(prefix_info)
    # logger.info(address_info)

    ephemeral_response_text = ""
    if prefix_info is not None and len(prefix_info) > 0:
        # ephemeral_response_text += "Prefix --> "+str(prefix_info[0].get('prefix'))+" | Description --> "+str(prefix_info[0].get('description'))+"\n"
        ephemeral_response_text = pprint.pformat(prefix_info[0], indent=4)

    elif address_info is not None and len(address_info) > 0:
        # ephemeral_response_text += "Address --> "+str(address_info[0].get('address'))+" | Description --> "+str(address_info[0].get('description'))+"\n"
        ephemeral_response_text = pprint.pformat(address_info[0], indent=4)
        
    elif prefix_contains_info is not None and len(prefix_contains_info) > 0:
        ephemeral_response_text += "Specific entry not found but is contained in the following Prefixes:\n"
        for item in prefix_contains_info:
            ephemeral_response_text += "Prefix --> "+str(item.get('prefix'))+" | Description --> "+str(item.get('description'))+"\n"

    else:
        ephemeral_response_text = "No Information Found for This Entry --> "+user_input

    return ephemeral_response_text


def lambda_handler(event, context):
    # logger.info(event)
    decode_body = b64decode(str(event['body'])).decode('ascii')
    params = parse_qs(decode_body)
    payload_dict = json.loads(params['payload'][0])
    # logger.info(payload_dict)
    # logger.info(type(payload_dict))
    token = payload_dict['token']
    if token != expected_token:
        logger.error("Request token (%s) does not match expected", token)
        return respond(Exception('Invalid request token'))

    # logger.info(payload_dict['actions'][0]['value'])

    if payload_dict['actions'][0]['value'] == "public_egress":
        ephemeral_response_body = {"text": action_get_public_nat()}

    if payload_dict['actions'][0]['value'] == "wireless_user_subnet":
        ephemeral_response_body = {"text": action_get_trusted_user_subnet()}

    if payload_dict['actions'][0]['value'] == "vpn_subnet":
        ephemeral_response_body = {"text": action_get_tagged_subnet(payload_dict['actions'][0]['value'])}

    if payload_dict['actions'][0]['action_id'] == "plain_text_input-action":
        user_input = payload_dict['actions'][0]['value']
        try:
            user_input_validated = ipaddress.ip_interface(user_input)
            user_input_encoded = urllib.parse.quote(str(user_input).encode('utf8'))
            ephemeral_response_body = {"text": action_get_more_info(user_input_encoded)}
        except ValueError as e:
            ephemeral_response_body = {"text": "You entered an Unrecognized IP or Prefix - Please Enter in the Format of 10.10.10.1 or 10.10.10.0/24"}

    send_msg = send_ephemeral_message(payload_dict['response_url'], ephemeral_response_body)
    logger.info(send_msg)

    api_response = {"text": "okay"}

    return respond(None, api_response)
