import json
import re
import boto3
from operator import itemgetter
from urllib.parse import unquote_plus
from fuzzywuzzy import fuzz
import pymysql

s3 = boto3.client('s3')
companies = ['AyudaMovistarCL','Banco_Falabella','Banco_Patagonia','BancoBci','BancoBci','bancoconsorcio','bancodechile','BancoEstado','bancogalicia','bancoprovincia','banmedica','bbva_argentina','CableFibertel','ClaroArgentina','clarochile_cl','entel','entel_ayuda','Fonasa','gtdchile','HSBC_AR','ICBCArgentina','ICruzBlanca','IsapreColmena','IsapreConsalud','itauchile','MovistarArg','MovistarChile','PersonalAr','prensabna','Santander_Ar','santanderchile','Scotiabank_CL','TeleCentroAr','TeleCentroAyuda','vidatres','VirginMobile_cl','VTRChile','VTRsoporte','womchile','WOMteAyuda']

def eval_text_handler(json_data):
    # If retweeted status
    if json_data.get('retweeted_status'):
        if json_data.get('retweeted_status').get('truncated'):
            json_data['retweetedTweet'] = json_data.get('retweeted_status').get('extended_tweet').get('full_text')
        else:
            json_data['retweetedTweet'] = json_data.get('retweeted_status').get('text')
    # If is_quote_status
    if json_data.get('is_quote_status'):
        if json_data.get('quoted_status').get('truncated'):
            json_data['quotedTweet'] = json_data.get('quoted_status').get('extended_tweet').get('full_text')
        else:
            json_data['quotedTweet'] = json_data.get('quoted_status').get('text')
    # If truncated
    if json_data.get('truncated'):
        json_data['tweet'] = json_data.get('extended_tweet').get('full_text')
    else:
        json_data['tweet'] = json_data.get('text')
    return json_data

def lambda_handler(event,context=None):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = unquote_plus(record['s3']['object']['key'])
        obj = s3.get_object(Bucket=bucket,Key=key)
        json_data = json.loads(obj['Body'].read())
        json_data = eval_text_handler(json_data)
        score = [(company,fuzz.token_set_ratio(json_data,company)) for company in companies]
        if max(score,key=itemgetter(1))[1] > 70:
            max_score_company = max(score,key=itemgetter(1))[0]
        else:
            max_score_company = 'unknown'
        json_data['company'] = max_score_company
        sql_conn = pymysql.connect(host='${host}',user='${user}',password='${password}',database='analytics')
        sql_query = "INSERT INTO tweets (id,tweetDate,source,user,followers,tweet,retweetedTweet,quotedTweet,company) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)"
        cursor = sql_conn.cursor()
        cursor.execute(sql_query,
                                (json_data['id'],
                                json_data['tweetDate'],
                                json_data['source'],
                                json_data['user']['screen_name'],
                                json_data['user']['followers_count'],
                                json_data['fullText'],
                                json_data['retweeted_status'],
                                json_data['quoted_status'],
                                json_data['company']
                                )
        )
        sql_conn.commit()
        sql_conn.close()
    return {"statusCode":200}