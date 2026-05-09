# 📚 Sistema de Gerenciamento de Banco de Dados

Projeto de banco de dados relacional desenvolvido para estudo e aplicação de conceitos de modelagem, normalização e consultas SQL.

---

# 🎯 Objetivo

Este projeto tem como objetivo desenvolver um banco de dados capaz de gerenciar informações de um sistema de forma estruturada e eficiente, aplicando conceitos fundamentais de banco de dados relacionais.

Principais objetivos:

- Modelagem de dados
- Criação de tabelas relacionais
- Aplicação de chaves primárias e estrangeiras
- Consultas SQL
- Normalização
- Manipulação de dados
- Simulação de cenário real

---

# 🛠 Tecnologias Utilizadas

- SQL
- MySQL
- MySQL Workbench
- Git
- GitHub

---

# 🧩 Modelagem do Banco

O banco foi modelado utilizando o modelo relacional com foco em organização, integridade e escalabilidade.

## Principais Entidades

- Usuários
- Produtos
- Pedidos
- Categorias
- Clientes

---

# 🗺 Diagrama Entidade-Relacionamento (DER)

> Adicione aqui a imagem do diagrama do banco.

```md
![DER](docs/diagrama_er.png)
```

---

# ⚙️ Como Executar o Projeto

## 1️⃣ Clone o repositório

```bash
git clone https://github.com/seu-usuario/projeto-banco-dados.git
```

---

## 2️⃣ Abra o SGBD

Abra o MySQL Workbench ou outro gerenciador SQL de sua preferência.

---

## 3️⃣ Crie o banco de dados

```sql
CREATE DATABASE projeto_bd;
USE projeto_bd;
```

---

## 4️⃣ Execute os scripts

Execute os arquivos na seguinte ordem:

1. `create_tables.sql`
2. `inserts.sql`
3. `queries.sql`
4. `views_triggers.sql`

---

# 🧪 Funcionalidades Implementadas

- Cadastro de usuários
- Cadastro de produtos
- Controle de pedidos
- Relacionamentos entre tabelas
- Consultas com JOIN
- Views
- Procedures
- Triggers
- Relatórios SQL

---

# 🔍 Exemplos de Consultas

## Buscar todos os usuários

```sql
SELECT * FROM usuarios;
```

---

## Buscar pedidos com clientes

```sql
SELECT 
    pedidos.id,
    clientes.nome,
    pedidos.valor_total
FROM pedidos
INNER JOIN clientes
ON pedidos.cliente_id = clientes.id;
```

---

## Buscar produtos por categoria

```sql
SELECT 
    produtos.nome,
    categorias.nome AS categoria
FROM produtos
INNER JOIN categorias
ON produtos.categoria_id = categorias.id;
```

---

# 📊 Conceitos Aplicados

- Modelo Entidade-Relacionamento (MER)
- Modelo Relacional
- Normalização
- Integridade Referencial
- Chaves Primárias e Estrangeiras
- Cardinalidade
- SQL DDL
- SQL DML
- SQL DQL

---

# 🚀 Melhorias Futuras

- Implementação de procedures avançadas
- Criação de triggers automáticas
- Sistema de auditoria
- Integração com API
- Migração para PostgreSQL
- Dashboard de visualização de dados

---

# 👥 Integrantes

- Henrique Chiosani
- Nome Integrante 2
- Nome Integrante 3

---

# 📖 Documentação

Os documentos do projeto podem ser encontrados na pasta:

```txt
/docs
```

---

# 💾 Backup do Banco

O backup do banco está disponível em:

```txt
/backup/backup.sql
```

---

# 📝 Licença

Este projeto foi desenvolvido para fins acadêmicos e de estudo.

---

# 📌 Observações

- Certifique-se de executar os scripts na ordem correta.
- O projeto pode ser adaptado para outros SGBDs com pequenas modificações.
- Recomenda-se utilizar MySQL 8+.

---

# ⭐ Contribuição

Contribuições são bem-vindas.

Caso queira melhorar o projeto:

1. Faça um fork
2. Crie uma branch
3. Commit suas alterações
4. Abra um Pull Request

---

# 📧 Contato

Caso tenha dúvidas ou sugestões:

- GitHub: https://github.com/seu-usuario
- Email: seu-email@email.com
