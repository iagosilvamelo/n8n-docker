import json
import uuid

wf_path = '/home/ubuntu/services/n8n/workflows/H3TjPx76MJA7VKoj.json'
with open(wf_path, 'r', encoding='utf-8') as f:
    wf = json.load(f)

# Código JS do nó de divisão por parágrafos
js_code = """const inputText = $('Formatar texto').first().json.text || '';

function splitIntoMessages(text, maxChars = 800) {
  if (!text || !text.trim()) return [];

  // Divide inicialmente por parágrafos (dupla quebra de linha)
  let paragraphs = text.split(/\\n\\s*\\n/).map(p => p.trim()).filter(Boolean);

  // Se o texto não tinha quebras duplas mas é grande, divide por quebras simples
  if (paragraphs.length === 1 && paragraphs[0].length > maxChars) {
    paragraphs = text.split(/\\n+/).map(p => p.trim()).filter(Boolean);
  }

  const chunks = [];

  for (const para of paragraphs) {
    if (para.length <= maxChars) {
      chunks.push(para);
    } else {
      // Divide sentenças mantendo pontuação
      const sentences = para.match(/[^.!?]+[.!?]+|\\s*[^.!?]+$/g) || [para];
      let current = '';
      for (const s of sentences) {
        if ((current + ' ' + s).trim().length <= maxChars) {
          current = (current + ' ' + s).trim();
        } else {
          if (current) chunks.push(current);
          current = s.trim();
        }
      }
      if (current) chunks.push(current);
    }
  }

  return chunks;
}

const partes = splitIntoMessages(inputText);
return partes.map((parte, index) => ({
  json: {
    texto_mensagem: parte,
    parte_index: index + 1,
    total_partes: partes.length
  }
}));"""

# 1. Verificar se o nó 'Dividir mensagens' já existe ou criar novo
split_node_id = None
for n in wf['nodes']:
    if n.get('name') == 'Dividir mensagens':
        split_node_id = n.get('id')
        n['parameters'] = {'jsCode': js_code}
        break

if not split_node_id:
    split_node_id = str(uuid.uuid4())
    split_node = {
        'parameters': {
            'jsCode': js_code
        },
        'type': 'n8n-nodes-base.code',
        'typeVersion': 2,
        'position': [4860, -128],
        'id': split_node_id,
        'name': 'Dividir mensagens'
    }
    wf['nodes'].append(split_node)

# 2. Atualizar o nó 'Enviar Texto'
for n in wf['nodes']:
    if n.get('name') == 'Enviar Texto':
        n['position'] = [5100, -128]
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
            'jsonBody': '={\n  "recipient": {\n    "id": "{{ $(\'Info\').item.json.remetente_id }}"\n  },\n  "message": {\n    "text": {{ JSON.stringify($json.texto_mensagem) }}\n  }\n}',
            'options': {
                'batching': {
                    'batch': {
                        'batchSize': 1,
                        'batchInterval': 1000
                    }
                }
            }
        }

# 3. Atualizar conexões
conns = wf.get('connections', {})

# Resetar status -> Dividir mensagens
conns['Resetar status'] = {
    'main': [
        [{'node': 'Dividir mensagens', 'type': 'main', 'index': 0}]
    ]
}

# Dividir mensagens -> Enviar Texto
conns['Dividir mensagens'] = {
    'main': [
        [{'node': 'Enviar Texto', 'type': 'main', 'index': 0}]
    ]
}

with open(wf_path, 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print('SUCCESS')
