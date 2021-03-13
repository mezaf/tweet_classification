import json
import re
import boto3
from operator import itemgetter
from urllib.parse import unquote_plus
from fuzzywuzzy import fuzz

s3 = boto3.client('s3')
companies = ['AyudaMovistarCL','Banco_Falabella','Banco_Patagonia','BancoBci','BancoBci','bancoconsorcio','bancodechile','BancoEstado','bancogalicia','bancoprovincia','banmedica','bbva_argentina','CableFibertel','ClaroArgentina','clarochile_cl','entel','entel_ayuda','Fonasa','gtdchile','HSBC_AR','ICBCArgentina','ICruzBlanca','IsapreColmena','IsapreConsalud','itauchile','MovistarArg','MovistarChile','PersonalAr','prensabna','Santander_Ar','santanderchile','Scotiabank_CL','TeleCentroAr','TeleCentroAyuda','vidatres','VirginMobile_cl','VTRChile','VTRsoporte','womchile','WOMteAyuda']
# print(json.dumps(sample,indent=4))

# If in_reply_to_status_id -> not relevant, will be handled for other conditions

def eval_text_handler(json_data):
    # If retweeted status
    if json_data.get('retweeted_status'):
        if json_data.get('retweeted_status').get('truncated'):
            return json_data.get('retweeted_status').get('extended_tweet').get('full_text')
        else:
            return json_data.get('retweeted_status').get('text')
    # If is_quote_status
    if json_data.get('is_quote_status'):
        if json_data.get('quoted_status').get('truncated'):
            return json_data.get('quoted_status').get('extended_tweet').get('full_text')
        else:
            return json_data.get('quoted_status').get('text')
    # If truncated
    if json_data.get('truncated'):
        return json_data.get('extended_tweet').get('full_text')
    else:
        return json_data.get('text')

def lambda_handler(event,context=None):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        date_key = re.match(r'(ymd=\d{8})',key)[1]
        file_key = re.match(r'ymd=\d{8}/(.*)',key)[1]
        obj = s3.get_object(Bucket=bucket,Key=key)
        json_data = json.loads(obj['Body'].read())
        eval_text = eval_text_handler(json_data)
        score = [(company,fuzz.token_set_ratio(eval_text,company)) for company in companies]
        max_score_company = max(score,key=itemgetter(1))[0]
        json_data['company'] = max_score_company
        new_key = 'data/{date_key}/company={company}/{file_key}'.format(date_key=date_key
                                                                            ,company=max_score_company
                                                                            ,file_key=file_key)
        s3.put_object(
            Body = json.dumps(json_data)
            ,Bucket = 'customer-twitter-cooked'
            ,Key = new_key
        )
    return {"statusCode":200}