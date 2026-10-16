import json
import uuid

wf_path = '/home/ubuntu/services/n8n/workflows/H3TjPx76MJA7VKoj.json'
with open(wf_path, 'r', encoding='utf-8') as f:
    wf = json.load(f)

# 1. Remover 'Respond to Webhook'
wf['nodes'] = [n for n in wf['nodes'] if n.get('name') != 'Respond to Webhook']
if 'Respond to Webhook' in wf.get('connections', {}):
    del wf['connections']['Respond to Webhook']

for n in wf['nodes']:
    name = n.get('name')
    
    # 2. Atualizar 'Info'
    if name == 'Info':
        assignments = n['parameters']['assignments']['assignments']
        existing_names = {a['name'] for a in assignments}
        
        new_vars = [
            {'name': 'id_mensagem', 'value': '={{ $json.body.entry[0].messaging[0].message.mid }}', 'type': 'string'},
            {'name': 'remetente_id', 'value': '={{ $json.body.entry[0].messaging[0].sender.id }}', 'type': 'string'},
            {'name': 'conta_id', 'value': '={{ $json.body.entry[0].id }}', 'type': 'string'},
            {'name': 'timestamp', 'value': '={{ $json.body.entry[0].messaging[0].timestamp }}', 'type': 'number'},
            {'name': 'mensagem', 'value': "={{ $json.body.entry[0].messaging[0].message.text || '' }}", 'type': 'string'},
            {'name': 'mensagem_de_audio', 'value': "={{ Boolean($json.body.entry[0].messaging[0].message.attachments && $json.body.entry[0].messaging[0].message.attachments[0] && $json.body.entry[0].messaging[0].message.attachments[0].type === 'audio') }}", 'type': 'boolean'},
            {'name': 'url_audio', 'value': "={{ $json.body.entry[0].messaging[0].message.attachments && $json.body.entry[0].messaging[0].message.attachments[0] && $json.body.entry[0].messaging[0].message.attachments[0].payload ? $json.body.entry[0].messaging[0].message.attachments[0].payload.url : '' }}", 'type': 'string'},
        ]
        
        for v in new_vars:
            if v['name'] not in existing_names:
                v['id'] = str(uuid.uuid4())
                assignments.append(v)
                
    # 3.2. Atualizar 'Guarda metadatas'
    elif name == 'Guarda metadatas':
        n['parameters']['query'] = (
            "INSERT INTO instagram_contas (instagram_account_id, ativa)\n"
            "VALUES ('{{ $('Info').item.json.instagram.userId }}', true)\n"
            "ON CONFLICT (instagram_account_id) DO UPDATE SET updated_at = NOW();\n\n"
            "INSERT INTO instagram_contatos (conta_id, instagram_user_id, ultima_interacao_em)\n"
            "SELECT id, '{{ $('Info').item.json.remetente_id }}', NOW()\n"
            "FROM instagram_contas\n"
            "WHERE instagram_account_id = '{{ $('Info').item.json.instagram.userId }}'\n"
            "ON CONFLICT (conta_id, instagram_user_id) \n"
            "DO UPDATE SET ultima_interacao_em = NOW();\n\n"
            "INSERT INTO instagram_conversas (conta_id, contato_id, canal, status, ultima_mensagem_em, ultima_mensagem_recebida_em)\n"
            "SELECT c.conta_id, c.id, 'direct', 'aberta', NOW(), NOW()\n"
            "FROM instagram_contatos c\n"
            "JOIN instagram_contas a ON a.id = c.conta_id\n"
            "WHERE a.instagram_account_id = '{{ $('Info').item.json.instagram.userId }}'\n"
            "  AND c.instagram_user_id = '{{ $('Info').item.json.remetente_id }}'\n"
            "ON CONFLICT DO NOTHING;\n\n"
            "UPDATE instagram_conversas \n"
            "SET ultima_mensagem_em = NOW(), ultima_mensagem_recebida_em = NOW()\n"
            "WHERE conta_id = (SELECT id FROM instagram_contas WHERE instagram_account_id = '{{ $('Info').item.json.instagram.userId }}')\n"
            "  AND contato_id = (SELECT id FROM instagram_contatos WHERE instagram_user_id = '{{ $('Info').item.json.remetente_id }}')\n"
            "  AND status = 'aberta';"
        )

    # 3.3.1. Enfileirar mensagem.
    elif name == 'Enfileirar mensagem.':
        n['parameters']['table']['value'] = 'instagram_fila_mensagens'
        n['parameters']['columns']['value'] = {
            'sender_id': "={{ $('Info').item.json.remetente_id }}",
            'mensagem': "={{ $('Info').item.json.mensagem }}",
            'timestamp': "={{ $('Info').item.json.timestamp.toDateTime() }}",
            'id_mensagem': "={{ $('Info').item.json.id_mensagem }}"
        }
        n['parameters']['columns']['schema'] = [
            {'id': 'id', 'displayName': 'id', 'required': False, 'defaultMatch': True, 'display': True, 'type': 'number', 'canBeUsedToMatch': True, 'removed': True},
            {'id': 'sender_id', 'displayName': 'sender_id', 'required': False, 'defaultMatch': False, 'display': True, 'type': 'string', 'canBeUsedToMatch': True},
            {'id': 'id_mensagem', 'displayName': 'id_mensagem', 'required': False, 'defaultMatch': False, 'display': True, 'type': 'string', 'canBeUsedToMatch': True},
            {'id': 'mensagem', 'displayName': 'mensagem', 'required': False, 'defaultMatch': False, 'display': True, 'type': 'string', 'canBeUsedToMatch': True},
            {'id': 'timestamp', 'displayName': 'timestamp', 'required': False, 'defaultMatch': False, 'display': True, 'type': 'dateTime', 'canBeUsedToMatch': True}
        ]

    # 3.3.1. Buscar mensagens
    elif name == 'Buscar mensagens':
        n['parameters']['table']['value'] = 'instagram_fila_mensagens'
        n['parameters']['where']['values'] = [
            {
                'column': 'sender_id',
                'value': "={{ $('Info').item.json.remetente_id }}"
            }
        ]

    # 3.3.1. Limpar fila de mensagens
    elif name == 'Limpar fila de mensagens':
        n['parameters']['table']['value'] = 'instagram_fila_mensagens'
        n['parameters']['where']['values'] = [
            {
                'column': 'sender_id',
                'value': "={{ $json.sender_id }}"
            }
        ]

    # 3.3.2. Download áudio
    elif name == 'Download áudio':
        n['parameters']['url'] = "={{ $('Info').item.json.url_audio }}"
        if 'authentication' in n['parameters']:
            del n['parameters']['authentication']
        if 'nodeCredentialType' in n['parameters']:
            del n['parameters']['nodeCredentialType']
        n['parameters']['options'] = {
            'response': {
                'response': {
                    'responseFormat': 'file'
                }
            }
        }

    # 4. Marcar como lidas
    elif name == 'Marcar como lidas':
        n['parameters'] = {
            'method': 'POST',
            'url': "=https://graph.instagram.com/v26.0/{{ $('Info').item.json.instagram.userId }}/messages",
            'sendHeaders': True,
            'headerParameters': {
                'parameters': [
                    {
                        'name': 'Authorization',
                        'value': "=Bearer {{ $('Info').item.json.instagram.token }}"
                    }
                ]
            },
            'sendBody': True,
            'contentType': 'json',
            'specifyBody': 'json',
            'jsonBody': '={\n  "recipient": {\n    "id": "{{ $(\'Info\').item.json.remetente_id }}"\n  },\n  "sender_action": "mark_seen"\n}',
            'options': {}
        }

    # 5. Digitando/Gravando...
    elif name == 'Digitando/Gravando...':
        n['parameters'] = {
            'method': 'POST',
            'url': "=https://graph.instagram.com/v26.0/{{ $('Info').item.json.instagram.userId }}/messages",
            'sendHeaders': True,
            'headerParameters': {
                'parameters': [
                    {
                        'name': 'Authorization',
                        'value': "=Bearer {{ $('Info').item.json.instagram.token }}"
                    }
                ]
            },
            'sendBody': True,
            'contentType': 'json',
            'specifyBody': 'json',
            'jsonBody': '={\n  "recipient": {\n    "id": "{{ $(\'Info\').item.json.remetente_id }}"\n  },\n  "sender_action": "typing_on"\n}',
            'options': {}
        }

with open(wf_path, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print('SUCCESS')
