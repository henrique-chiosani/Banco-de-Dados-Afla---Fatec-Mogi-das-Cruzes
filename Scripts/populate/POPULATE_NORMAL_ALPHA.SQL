
/* ============================================================
   SECAO 1 - POPULACAO TABELA LOJA
   ============================================================ */

INSERT INTO LOJA (LOJ_NOME)
SELECT DISTINCT LOJA_STG
FROM STG_ALFA
WHERE LOJA_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2025-11-01'
  AND DATA_PEDIDO_STG <  DATE '2025-12-01';

COMMIT;
/


/* ============================================================
   SECAO 2 - POPULACAO TABELA CANAL
   ============================================================ */

INSERT INTO CANAL (CAN_NOME)
SELECT DISTINCT CANAL_STG
FROM STG_ALFA
WHERE CANAL_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2025-11-01'
  AND DATA_PEDIDO_STG <  DATE '2025-12-01';

COMMIT;
/


/* ============================================================
   SECAO 3 - POPULACAO TABELA PRODUTO
   ============================================================ */

INSERT INTO PRODUTO (PRD_NOME)
SELECT DISTINCT DESCRICAO_STG
FROM STG_ALFA
WHERE DESCRICAO_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2025-11-01'
  AND DATA_PEDIDO_STG <  DATE '2025-12-01';

COMMIT;
/


/* ============================================================
   SECAO 4 - POPULACAO TABELA SKU
   ============================================================ */

INSERT INTO SKU (
    SKU_KEY,
    SKU_PRD_ID,
    SKU_CUSTO
)
SELECT
    STG.SKU_STG,
    PRD.PRD_ID,
    STG.CUSTO_STG
FROM (
    SELECT
        SKU_STG,
        DESCRICAO_STG,
        CUSTO_STG,
        ROW_NUMBER() OVER (
            PARTITION BY SKU_STG
            ORDER BY DATA_PEDIDO_STG DESC
        ) AS RN
    FROM STG_ALFA
    WHERE DATA_PEDIDO_STG >= DATE '2025-11-01'
      AND DATA_PEDIDO_STG <  DATE '2025-12-01'
) STG
INNER JOIN PRODUTO PRD
    ON PRD.PRD_NOME = STG.DESCRICAO_STG
WHERE STG.RN = 1
  AND NOT EXISTS (
    SELECT 1
    FROM SKU
    WHERE SKU.SKU_KEY = STG.SKU_STG
);

COMMIT;
/

/* ============================================================
   SECAO 5 - POPULACAO TABELA VENDA
   ============================================================ */

INSERT INTO VENDA (
    VND_PEDIDO,
    VND_LOJ_ID,
    VND_CAN_ID,
    VND_DATA_VENDA,
    VND_VALOR_TOTAL
)
SELECT
    STG.PEDIDO_STG,
    LOJ.LOJ_ID,
    CAN.CAN_ID,
    STG.DATA_PEDIDO_STG,
    ITV.VALOR_TOTAL_ITENS
FROM (
    SELECT
        PEDIDO_STG,
        LOJA_STG,
        CANAL_STG,
        DATA_PEDIDO_STG,
        ROW_NUMBER() OVER (
            PARTITION BY PEDIDO_STG
            ORDER BY DATA_PEDIDO_STG DESC
        ) AS RN
    FROM (
        SELECT DISTINCT
            PEDIDO_STG,
            LOJA_STG,
            CANAL_STG,
            DATA_PEDIDO_STG
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2025-11-01'
          AND DATA_PEDIDO_STG <  DATE '2025-12-01'
    )
) STG
INNER JOIN (
    SELECT
        PEDIDO_STG,
        SUM(QTDE_STG  * CUSTO_STG) AS CUSTO_TOTAL_ITENS,
        SUM(VALOR_STG)             AS VALOR_TOTAL_ITENS
    FROM (
        SELECT
            PEDIDO_STG,
            SKU_STG,
            SUM(QTDE_STG)  AS QTDE_STG,
            MAX(CUSTO_STG) AS CUSTO_STG,
            SUM(VALOR_STG) AS VALOR_STG
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2025-11-01'
          AND DATA_PEDIDO_STG <  DATE '2025-12-01'
        GROUP BY
            PEDIDO_STG,
            SKU_STG
    )
    GROUP BY PEDIDO_STG
) ITV
    ON ITV.PEDIDO_STG = STG.PEDIDO_STG
INNER JOIN LOJA LOJ
    ON LOJ.LOJ_NOME = STG.LOJA_STG
INNER JOIN CANAL CAN
    ON CAN.CAN_NOME = STG.CANAL_STG
WHERE STG.RN = 1
  AND NOT EXISTS (
    SELECT 1
    FROM VENDA
    WHERE VENDA.VND_PEDIDO = STG.PEDIDO_STG
);

COMMIT;
/


/* ============================================================
   SECAO 6 - POPULACAO TABELA ITEM_VENDA
   ============================================================ */

INSERT INTO ITEM_VENDA (
    ITVND_VND_ID,
    ITVND_SKU_ID,
    ITVND_QTDE,
    ITVND_CUSTO,
    ITVND_VALOR
)
SELECT
    VND.VND_ID,
    SKU.SKU_ID,
    STG.QTDE_STG,
    STG.CUSTO_STG,
    STG.VALOR_STG
FROM (
    SELECT
        PEDIDO_STG,
        SKU_STG,
        SUM(QTDE_STG)  AS QTDE_STG,
        MAX(CUSTO_STG) AS CUSTO_STG,
        SUM(VALOR_STG) AS VALOR_STG
    FROM STG_ALFA
    WHERE DATA_PEDIDO_STG >= DATE '2025-11-01'
      AND DATA_PEDIDO_STG <  DATE '2025-12-01'
    GROUP BY
        PEDIDO_STG,
        SKU_STG
) STG
INNER JOIN VENDA VND
    ON VND.VND_PEDIDO = STG.PEDIDO_STG
INNER JOIN SKU SKU
    ON SKU.SKU_KEY = STG.SKU_STG
WHERE NOT EXISTS (
    SELECT 1
    FROM ITEM_VENDA
    WHERE ITEM_VENDA.ITVND_VND_ID = VND.VND_ID
      AND ITEM_VENDA.ITVND_SKU_ID = SKU.SKU_ID
);

COMMIT;
