

/* ------------------------------------------------------------
   1.1 - LOJA
   INSERT apenas se a loja ainda nao existe
   ------------------------------------------------------------ */

INSERT INTO LOJA (LOJ_NOME)
SELECT DISTINCT LOJA_STG
FROM STG_ALFA
WHERE LOJA_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2025-12-01'
  AND DATA_PEDIDO_STG <  DATE '2026-01-01'
  AND NOT EXISTS (
    SELECT 1
    FROM LOJA
    WHERE LOJA.LOJ_NOME = STG_ALFA.LOJA_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   1.2 - CANAL
   INSERT apenas se o canal ainda nao existe
   ------------------------------------------------------------ */

INSERT INTO CANAL (CAN_NOME)
SELECT DISTINCT CANAL_STG
FROM STG_ALFA
WHERE CANAL_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2025-12-01'
  AND DATA_PEDIDO_STG <  DATE '2026-01-01'
  AND NOT EXISTS (
    SELECT 1
    FROM CANAL
    WHERE CANAL.CAN_NOME = STG_ALFA.CANAL_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   1.3 - PRODUTO
   INSERT apenas se o produto ainda nao existe
   ------------------------------------------------------------ */

INSERT INTO PRODUTO (PRD_NOME)
SELECT DISTINCT DESCRICAO_STG
FROM STG_ALFA
WHERE DESCRICAO_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2025-12-01'
  AND DATA_PEDIDO_STG <  DATE '2026-01-01'
  AND NOT EXISTS (
    SELECT 1
    FROM PRODUTO
    WHERE PRODUTO.PRD_NOME = STG_ALFA.DESCRICAO_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   1.4A - SKU (INSERT)
   INSERT apenas para SKUs que ainda nao existem
   ------------------------------------------------------------ */

INSERT INTO SKU (SKU_KEY, SKU_PRD_ID, SKU_CUSTO)
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
    WHERE DATA_PEDIDO_STG >= DATE '2025-12-01'
      AND DATA_PEDIDO_STG <  DATE '2026-01-01'
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


/* ------------------------------------------------------------
   1.4B - SKU (UPDATE)
   UPDATE apenas quando o custo mudou
   >> TG_HSKU dispara e grava valor antigo em HSKU
   ------------------------------------------------------------ */

UPDATE SKU
SET SKU_CUSTO = (
    SELECT STG.CUSTO_STG
    FROM (
        SELECT
            SKU_STG,
            CUSTO_STG,
            ROW_NUMBER() OVER (
                PARTITION BY SKU_STG
                ORDER BY DATA_PEDIDO_STG DESC
            ) AS RN
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2025-12-01'
          AND DATA_PEDIDO_STG <  DATE '2026-01-01'
    ) STG
    WHERE STG.RN      = 1
      AND STG.SKU_STG = SKU.SKU_KEY
)
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT
            SKU_STG,
            CUSTO_STG,
            ROW_NUMBER() OVER (
                PARTITION BY SKU_STG
                ORDER BY DATA_PEDIDO_STG DESC
            ) AS RN
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2025-12-01'
          AND DATA_PEDIDO_STG <  DATE '2026-01-01'
    ) STG
    WHERE STG.RN        = 1
      AND STG.SKU_STG   = SKU.SKU_KEY
      AND STG.CUSTO_STG <> SKU.SKU_CUSTO
);

COMMIT;
/


/* ------------------------------------------------------------
   1.5 - VENDA (INSERT)
   INSERT apenas para pedidos que ainda nao existem
   ------------------------------------------------------------ */

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
        WHERE DATA_PEDIDO_STG >= DATE '2025-12-01'
          AND DATA_PEDIDO_STG <  DATE '2026-01-01'
    )
) STG
INNER JOIN (
    SELECT
        PEDIDO_STG,
        SUM(VALOR_STG) AS VALOR_TOTAL_ITENS
    FROM (
        SELECT
            PEDIDO_STG,
            SKU_STG,
            SUM(VALOR_STG) AS VALOR_STG
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2025-12-01'
          AND DATA_PEDIDO_STG <  DATE '2026-01-01'
        GROUP BY PEDIDO_STG, SKU_STG
    )
    GROUP BY PEDIDO_STG
) ITV
    ON ITV.PEDIDO_STG = STG.PEDIDO_STG
INNER JOIN LOJA LOJ ON LOJ.LOJ_NOME = STG.LOJA_STG
INNER JOIN CANAL CAN ON CAN.CAN_NOME = STG.CANAL_STG
WHERE STG.RN = 1
  AND NOT EXISTS (
    SELECT 1
    FROM VENDA
    WHERE VENDA.VND_PEDIDO = STG.PEDIDO_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   1.6 - ITEM_VENDA (INSERT)
   INSERT apenas para itens que ainda nao existem
   ------------------------------------------------------------ */

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
    WHERE DATA_PEDIDO_STG >= DATE '2025-12-01'
      AND DATA_PEDIDO_STG <  DATE '2026-01-01'
    GROUP BY PEDIDO_STG, SKU_STG
) STG
INNER JOIN VENDA VND ON VND.VND_PEDIDO = STG.PEDIDO_STG
INNER JOIN SKU   SKU ON SKU.SKU_KEY    = STG.SKU_STG
WHERE NOT EXISTS (
    SELECT 1
    FROM ITEM_VENDA
    WHERE ITEM_VENDA.ITVND_VND_ID = VND.VND_ID
      AND ITEM_VENDA.ITVND_SKU_ID = SKU.SKU_ID
  );

COMMIT;
/


/* ------------------------------------------------------------
   1.7A - DELETE ITEM_VENDA de NOVEMBRO/2025
   >> TG_HITVND dispara e grava cada linha em HITEM_VENDA
   OBRIGATORIO: deletar filho antes do pai (FK)
   ------------------------------------------------------------ */

DELETE FROM ITEM_VENDA
WHERE ITVND_VND_ID IN (
    SELECT VND_ID
    FROM VENDA
    WHERE VND_DATA_VENDA >= DATE '2025-11-01'
      AND VND_DATA_VENDA <  DATE '2025-12-01'
);

COMMIT;
/


/* ------------------------------------------------------------
   1.7B - DELETE VENDA de NOVEMBRO/2025
   >> TG_HVND dispara e grava cada linha em HVENDA
   ------------------------------------------------------------ */

DELETE FROM VENDA
WHERE VND_DATA_VENDA >= DATE '2025-11-01'
  AND VND_DATA_VENDA <  DATE '2025-12-01';

COMMIT;
/




/* ============================================================
   ============================================================
   BLOCO 2 - CARGA JANEIRO/2026
   - Carrega dados de: 2026-01-01 ate 2026-01-31
   - Remove dados de:  2025-12-01 ate 2025-12-31
   ============================================================
   ============================================================ */


/* ------------------------------------------------------------
   2.1 - LOJA
   ------------------------------------------------------------ */

INSERT INTO LOJA (LOJ_NOME)
SELECT DISTINCT LOJA_STG
FROM STG_ALFA
WHERE LOJA_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2026-01-01'
  AND DATA_PEDIDO_STG <  DATE '2026-02-01'
  AND NOT EXISTS (
    SELECT 1
    FROM LOJA
    WHERE LOJA.LOJ_NOME = STG_ALFA.LOJA_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   2.2 - CANAL
   ------------------------------------------------------------ */

INSERT INTO CANAL (CAN_NOME)
SELECT DISTINCT CANAL_STG
FROM STG_ALFA
WHERE CANAL_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2026-01-01'
  AND DATA_PEDIDO_STG <  DATE '2026-02-01'
  AND NOT EXISTS (
    SELECT 1
    FROM CANAL
    WHERE CANAL.CAN_NOME = STG_ALFA.CANAL_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   2.3 - PRODUTO
   ------------------------------------------------------------ */

INSERT INTO PRODUTO (PRD_NOME)
SELECT DISTINCT DESCRICAO_STG
FROM STG_ALFA
WHERE DESCRICAO_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2026-01-01'
  AND DATA_PEDIDO_STG <  DATE '2026-02-01'
  AND NOT EXISTS (
    SELECT 1
    FROM PRODUTO
    WHERE PRODUTO.PRD_NOME = STG_ALFA.DESCRICAO_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   2.4A - SKU (INSERT)
   ------------------------------------------------------------ */

INSERT INTO SKU (SKU_KEY, SKU_PRD_ID, SKU_CUSTO)
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
    WHERE DATA_PEDIDO_STG >= DATE '2026-01-01'
      AND DATA_PEDIDO_STG <  DATE '2026-02-01'
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


/* ------------------------------------------------------------
   2.4B - SKU (UPDATE)
   >> TG_HSKU dispara e grava valor antigo em HSKU
   ------------------------------------------------------------ */

UPDATE SKU
SET SKU_CUSTO = (
    SELECT STG.CUSTO_STG
    FROM (
        SELECT
            SKU_STG,
            CUSTO_STG,
            ROW_NUMBER() OVER (
                PARTITION BY SKU_STG
                ORDER BY DATA_PEDIDO_STG DESC
            ) AS RN
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2026-01-01'
          AND DATA_PEDIDO_STG <  DATE '2026-02-01'
    ) STG
    WHERE STG.RN      = 1
      AND STG.SKU_STG = SKU.SKU_KEY
)
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT
            SKU_STG,
            CUSTO_STG,
            ROW_NUMBER() OVER (
                PARTITION BY SKU_STG
                ORDER BY DATA_PEDIDO_STG DESC
            ) AS RN
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2026-01-01'
          AND DATA_PEDIDO_STG <  DATE '2026-02-01'
    ) STG
    WHERE STG.RN        = 1
      AND STG.SKU_STG   = SKU.SKU_KEY
      AND STG.CUSTO_STG <> SKU.SKU_CUSTO
);

COMMIT;
/


/* ------------------------------------------------------------
   2.5 - VENDA (INSERT)
   ------------------------------------------------------------ */

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
        WHERE DATA_PEDIDO_STG >= DATE '2026-01-01'
          AND DATA_PEDIDO_STG <  DATE '2026-02-01'
    )
) STG
INNER JOIN (
    SELECT
        PEDIDO_STG,
        SUM(VALOR_STG) AS VALOR_TOTAL_ITENS
    FROM (
        SELECT
            PEDIDO_STG,
            SKU_STG,
            SUM(VALOR_STG) AS VALOR_STG
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2026-01-01'
          AND DATA_PEDIDO_STG <  DATE '2026-02-01'
        GROUP BY PEDIDO_STG, SKU_STG
    )
    GROUP BY PEDIDO_STG
) ITV
    ON ITV.PEDIDO_STG = STG.PEDIDO_STG
INNER JOIN LOJA LOJ ON LOJ.LOJ_NOME = STG.LOJA_STG
INNER JOIN CANAL CAN ON CAN.CAN_NOME = STG.CANAL_STG
WHERE STG.RN = 1
  AND NOT EXISTS (
    SELECT 1
    FROM VENDA
    WHERE VENDA.VND_PEDIDO = STG.PEDIDO_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   2.6 - ITEM_VENDA (INSERT)
   ------------------------------------------------------------ */

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
    WHERE DATA_PEDIDO_STG >= DATE '2026-01-01'
      AND DATA_PEDIDO_STG <  DATE '2026-02-01'
    GROUP BY PEDIDO_STG, SKU_STG
) STG
INNER JOIN VENDA VND ON VND.VND_PEDIDO = STG.PEDIDO_STG
INNER JOIN SKU   SKU ON SKU.SKU_KEY    = STG.SKU_STG
WHERE NOT EXISTS (
    SELECT 1
    FROM ITEM_VENDA
    WHERE ITEM_VENDA.ITVND_VND_ID = VND.VND_ID
      AND ITEM_VENDA.ITVND_SKU_ID = SKU.SKU_ID
  );

COMMIT;
/


/* ------------------------------------------------------------
   2.7A - DELETE ITEM_VENDA de DEZEMBRO/2025
   >> TG_HITVND dispara e grava cada linha em HITEM_VENDA
   ------------------------------------------------------------ */

DELETE FROM ITEM_VENDA
WHERE ITVND_VND_ID IN (
    SELECT VND_ID
    FROM VENDA
    WHERE VND_DATA_VENDA >= DATE '2025-12-01'
      AND VND_DATA_VENDA <  DATE '2026-01-01'
);

COMMIT;
/


/* ------------------------------------------------------------
   2.7B - DELETE VENDA de DEZEMBRO/2025
   >> TG_HVND dispara e grava cada linha em HVENDA
   ------------------------------------------------------------ */

DELETE FROM VENDA
WHERE VND_DATA_VENDA >= DATE '2025-12-01'
  AND VND_DATA_VENDA <  DATE '2026-01-01';

COMMIT;
/




/* ============================================================
   ============================================================
   BLOCO 3 - CARGA FEVEREIRO/2026
   - Carrega dados de: 2026-02-01 ate 2026-02-28
   - Remove dados de:  2026-01-01 ate 2026-01-31
   ============================================================
   ============================================================ */


/* ------------------------------------------------------------
   3.1 - LOJA
   ------------------------------------------------------------ */

INSERT INTO LOJA (LOJ_NOME)
SELECT DISTINCT LOJA_STG
FROM STG_ALFA
WHERE LOJA_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2026-02-01'
  AND DATA_PEDIDO_STG <  DATE '2026-03-01'
  AND NOT EXISTS (
    SELECT 1
    FROM LOJA
    WHERE LOJA.LOJ_NOME = STG_ALFA.LOJA_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   3.2 - CANAL
   ------------------------------------------------------------ */

INSERT INTO CANAL (CAN_NOME)
SELECT DISTINCT CANAL_STG
FROM STG_ALFA
WHERE CANAL_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2026-02-01'
  AND DATA_PEDIDO_STG <  DATE '2026-03-01'
  AND NOT EXISTS (
    SELECT 1
    FROM CANAL
    WHERE CANAL.CAN_NOME = STG_ALFA.CANAL_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   3.3 - PRODUTO
   ------------------------------------------------------------ */

INSERT INTO PRODUTO (PRD_NOME)
SELECT DISTINCT DESCRICAO_STG
FROM STG_ALFA
WHERE DESCRICAO_STG IS NOT NULL
  AND DATA_PEDIDO_STG >= DATE '2026-02-01'
  AND DATA_PEDIDO_STG <  DATE '2026-03-01'
  AND NOT EXISTS (
    SELECT 1
    FROM PRODUTO
    WHERE PRODUTO.PRD_NOME = STG_ALFA.DESCRICAO_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   3.4A - SKU (INSERT)
   ------------------------------------------------------------ */

INSERT INTO SKU (SKU_KEY, SKU_PRD_ID, SKU_CUSTO)
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
    WHERE DATA_PEDIDO_STG >= DATE '2026-02-01'
      AND DATA_PEDIDO_STG <  DATE '2026-03-01'
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


/* ------------------------------------------------------------
   3.4B - SKU (UPDATE)
   >> TG_HSKU dispara e grava valor antigo em HSKU
   ------------------------------------------------------------ */

UPDATE SKU
SET SKU_CUSTO = (
    SELECT STG.CUSTO_STG
    FROM (
        SELECT
            SKU_STG,
            CUSTO_STG,
            ROW_NUMBER() OVER (
                PARTITION BY SKU_STG
                ORDER BY DATA_PEDIDO_STG DESC
            ) AS RN
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2026-02-01'
          AND DATA_PEDIDO_STG <  DATE '2026-03-01'
    ) STG
    WHERE STG.RN      = 1
      AND STG.SKU_STG = SKU.SKU_KEY
)
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT
            SKU_STG,
            CUSTO_STG,
            ROW_NUMBER() OVER (
                PARTITION BY SKU_STG
                ORDER BY DATA_PEDIDO_STG DESC
            ) AS RN
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2026-02-01'
          AND DATA_PEDIDO_STG <  DATE '2026-03-01'
    ) STG
    WHERE STG.RN        = 1
      AND STG.SKU_STG   = SKU.SKU_KEY
      AND STG.CUSTO_STG <> SKU.SKU_CUSTO
);

COMMIT;
/


/* ------------------------------------------------------------
   3.5 - VENDA (INSERT)
   ------------------------------------------------------------ */

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
        WHERE DATA_PEDIDO_STG >= DATE '2026-02-01'
          AND DATA_PEDIDO_STG <  DATE '2026-03-01'
    )
) STG
INNER JOIN (
    SELECT
        PEDIDO_STG,
        SUM(VALOR_STG) AS VALOR_TOTAL_ITENS
    FROM (
        SELECT
            PEDIDO_STG,
            SKU_STG,
            SUM(VALOR_STG) AS VALOR_STG
        FROM STG_ALFA
        WHERE DATA_PEDIDO_STG >= DATE '2026-02-01'
          AND DATA_PEDIDO_STG <  DATE '2026-03-01'
        GROUP BY PEDIDO_STG, SKU_STG
    )
    GROUP BY PEDIDO_STG
) ITV
    ON ITV.PEDIDO_STG = STG.PEDIDO_STG
INNER JOIN LOJA LOJ ON LOJ.LOJ_NOME = STG.LOJA_STG
INNER JOIN CANAL CAN ON CAN.CAN_NOME = STG.CANAL_STG
WHERE STG.RN = 1
  AND NOT EXISTS (
    SELECT 1
    FROM VENDA
    WHERE VENDA.VND_PEDIDO = STG.PEDIDO_STG
  );

COMMIT;
/


/* ------------------------------------------------------------
   3.6 - ITEM_VENDA (INSERT)
   ------------------------------------------------------------ */

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
    WHERE DATA_PEDIDO_STG >= DATE '2026-02-01'
      AND DATA_PEDIDO_STG <  DATE '2026-03-01'
    GROUP BY PEDIDO_STG, SKU_STG
) STG
INNER JOIN VENDA VND ON VND.VND_PEDIDO = STG.PEDIDO_STG
INNER JOIN SKU   SKU ON SKU.SKU_KEY    = STG.SKU_STG
WHERE NOT EXISTS (
    SELECT 1
    FROM ITEM_VENDA
    WHERE ITEM_VENDA.ITVND_VND_ID = VND.VND_ID
      AND ITEM_VENDA.ITVND_SKU_ID = SKU.SKU_ID
  );

COMMIT;
/


/* ------------------------------------------------------------
   3.7A - DELETE ITEM_VENDA de JANEIRO/2026
   >> TG_HITVND dispara e grava cada linha em HITEM_VENDA
   ------------------------------------------------------------ */

DELETE FROM ITEM_VENDA
WHERE ITVND_VND_ID IN (
    SELECT VND_ID
    FROM VENDA
    WHERE VND_DATA_VENDA >= DATE '2026-01-01'
      AND VND_DATA_VENDA <  DATE '2026-02-01'
);

COMMIT;
/


/* ------------------------------------------------------------
   3.7B - DELETE VENDA de JANEIRO/2026
   >> TG_HVND dispara e grava cada linha em HVENDA
   ------------------------------------------------------------ */

DELETE FROM VENDA
WHERE VND_DATA_VENDA >= DATE '2026-01-01'
  AND VND_DATA_VENDA <  DATE '2026-02-01';

COMMIT;
/
