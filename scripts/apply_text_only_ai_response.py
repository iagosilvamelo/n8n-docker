import json

wf_path = '/home/ubuntu/services/n8n/workflows/H3TjPx76MJA7VKoj.json'
with open(wf_path, 'r', encoding='utf-8') as f:
    wf = json.load(f)

nodes_to_remove = {
    'Formatar SSML', 'Google Gemini Chat Model.', 'Gerar áudio',
    'Áudio para base64', 'Tipo de mensagem1', 'Tipo de mensagem2',
    'Edit Fields', 'Base64 para áudio', 'Enviar áudio'
}

# 1. Filtrar lista de nós
wf['nodes'] = [n for n in wf['nodes'] if n.get('name') not in nodes_to_remove]

# 2. Atualizar parâmetros dos nós mantidos
for n in wf['nodes']:
    name = n.get('name')
    
    # Memória LangChain
    if name == 'Memory':
        n['parameters']['sessionKey'] = "={{ $('Info').item.json.remetente_id }}"
        n['parameters']['tableName'] = 'instagram_historico_mensagens'
        
    # Verifica DB
    elif name == 'Verifica DB':
        n['parameters']['table']['value'] = 'instagram_historico_mensagens'
        if 'cachedResultName' in n['parameters']['table']:
            n['parameters']['table']['cachedResultName'] = 'instagram_historico_mensagens'
        n['parameters']['where']['values'][0]['value'] = "={{ $('Info').item.json.remetente_id }}"
        
    # Corrige registro
    elif name == 'Corrige registro':
        n['parameters']['table']['value'] = 'instagram_historico_mensagens'
        if 'cachedResultName' in n['parameters']['table']:
            n['parameters']['table']['cachedResultName'] = 'instagram_historico_mensagens'
        n['parameters']['columns']['value']['id'] = "={{ $('Verifica DB').item.json.id }}"
        
    # Escalar humano
    elif name == 'Escalar humano':
        n['parameters']['workflowInputs']['value']['phone_number'] = "={{ $('Info').item.json.remetente_id }}"
        
    # Limpar historico
    elif name == 'Limpar historico':
        n['parameters']['workflowInputs']['value']['session_id'] = "={{ $('Info').item.json.remetente_id }}"
        
    # Resetar status (typing_off no Instagram)
    elif name == 'Resetar status':
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
            'jsonBody': '={\n  "recipient": {\n    "id": "{{ $(\'Info\').item.json.remetente_id }}"\n  },\n  "sender_action": "typing_off"\n}',
            'options': {}
        }
        
    # Enviar Texto (Instagram)
    elif name == 'Enviar Texto':
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
            'jsonBody': '={\n  "recipient": {\n    "id": "{{ $(\'Info\').item.json.remetente_id }}"\n  },\n  "message": {\n    "text": {{ JSON.stringify($(\'Formatar texto\').item.json.text) }}\n  }\n}',
            'options': {}
        }

# 3. Atualizar conexões
conns = wf.get('connections', {})

# Remover nós deletados das conexões como origem
for node_name in nodes_to_remove:
    if node_name in conns:
        del conns[node_name]

# Remover referências a nós deletados nos destinos de outros nós
for src, types in conns.items():
    for conn_type, outputs in types.items():
        for i, target_list in enumerate(outputs):
            outputs[i] = [t for t in target_list if t.get('node') not in nodes_to_remove]

# Configurar o novo fluxo linear para texto:
# Mensagem com erro? -> True (Corrige registro), False (Formatar texto)
conns['Mensagem com erro?'] = {
    'main': [
        [{'node': 'Corrige registro', 'type': 'main', 'index': 0}],
        [{'node': 'Formatar texto', 'type': 'main', 'index': 0}]
    ]
}

# Corrige registro -> Formatar texto
conns['Corrige registro'] = {
    'main': [
        [{'node': 'Formatar texto', 'type': 'main', 'index': 0}]
    ]
}

# Formatar texto -> Resetar status
conns['Formatar texto'] = {
    'main': [
        [{'node': 'Resetar status', 'type': 'main', 'index': 0}]
    ]
}

# Resetar status -> Enviar Texto
conns['Resetar status'] = {
    'main': [
        [{'node': 'Enviar Texto', 'type': 'main', 'index': 0}]
    ]
}

with open(wf_path, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print('SUCCESS')
