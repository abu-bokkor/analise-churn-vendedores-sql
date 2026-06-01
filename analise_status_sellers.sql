WITH meses AS (
    SELECT
        -- Apenas os meses de referencia
        DISTINCT
        strftime('%Y-%m-01', order_approved_at) AS mes_referencia,
        1 AS chave
    FROM tb_orders
    WHERE mes_referencia IS NOT NULL
    ORDER BY 1 ASC
),

sellers AS (
    SELECT
        -- Info dos sellers com o mes de primeira venda
        t1.seller_id,
        min(strftime('%Y-%m-01', t2.order_approved_at)) AS mes_primeira_venda,
        1 AS chave
    FROM tb_order_items AS t1
    LEFT JOIN tb_orders AS t2
        ON t1.order_id = t2.order_id
    GROUP BY 1
),

cruzamento AS (
    SELECT
        -- Trazendo info de meses e sellers com as chaves ficticio
        t1.mes_referencia,
        t2.seller_id,
        t2.mes_primeira_venda
    FROM meses AS t1
    LEFT JOIN sellers AS t2
        ON t1.chave = t2.chave
    ORDER BY seller_id, mes_referencia
),

vendas AS (
    SELECT
        -- Somando o valor de venda dos sellers
        t1.seller_id,
        strftime('%Y-%m-01', t2.order_approved_at) AS mes_venda,
        SUM(t1.price) + SUM(t1.freight_value) AS valor_total
    FROM tb_order_items AS t1
    LEFT JOIN tb_orders AS t2
        ON t1.order_id = t2.order_id
    GROUP BY 1, 2
),

resultado AS(
    SELECT
        -- Aqui onde consego ver o histórico de cada vendedor com valor de venda
        t1.mes_referencia,
        t1.seller_id,
        t1.mes_primeira_venda,
        COALESCE(SUM(t2.valor_total), 0) AS valor_total
    FROM cruzamento AS t1
    LEFT JOIN vendas AS t2
        ON t1.seller_id = t2.seller_id AND t1.mes_referencia = t2.mes_venda
    GROUP BY 1, 2, 3
    ORDER BY t1.seller_id, t1.mes_referencia
),

ativo AS(
    SELECT
        -- Defini sinalizar por 0 ou 1 para classificar no CTE cassificado
        *,
        CASE
            WHEN valor_total > 0 THEN 1 ELSE 0
        END AS ativo
    FROM resultado
),

ativo_lag AS(
    SELECT
        -- Para verificar a coluna anterior que é ativo
        *,
        LAG(ativo) OVER(PARTITION BY seller_id ORDER BY mes_referencia ASC) AS ativo_lag
    FROM ativo
),

classificado AS (
    SELECT
        -- Classifiquei status dos sellers com mes de referencia
        *,
        CASE
            WHEN mes_primeira_venda > mes_referencia THEN 'Prior Entry'
            WHEN mes_primeira_venda = mes_referencia THEN 'Novo'
            WHEN ativo = 1 AND ativo_lag = 1 THEN 'Regular'
            WHEN ativo = 0 THEN 'Churn'
            WHEN ativo = 1 AND ativo_lag = 0 THEN 'Recuperado'
        END AS classificacao
    FROM ativo_lag
),

agrupa_sequencia AS (
    SELECT
        -- Criei um ID de grupo que agrupa status iguais consecutivos
        *,
        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY mes_referencia) -
        ROW_NUMBER() OVER (PARTITION BY seller_id, classificacao ORDER BY mes_referencia) AS id_grupo_status
    FROM classificado
),

conta_sequencia AS (
    SELECT
        -- Conta a repetição dentro desse grupo consecutivo
        *,
        ROW_NUMBER() OVER (PARTITION BY seller_id, classificacao, id_grupo_status
        ORDER BY mes_referencia) AS repeticao
    FROM agrupa_sequencia
),

resultado_final AS(
    SELECT 
        -- Aplicando a regra de identificar qntd de churn seguidos do seller
        mes_referencia,
        seller_id,
        mes_primeira_venda,
        valor_total,
        ativo,
        ativo_lag,
        classificacao,
        CASE 
            -- Quando for Churn, aplica a regra de repetição
            WHEN classificacao = 'Churn' THEN 
                CASE 
                    WHEN repeticao = 1 THEN 'Churn'
                    WHEN repeticao = 2 THEN 'Churn 2'
                    WHEN repeticao = 3 THEN 'Churn 3'
                    WHEN repeticao >= 4 THEN 'Churn 4+'
                END
            -- Se não for Churn, mantém outros status original
            ELSE classificacao 
        END AS classificacao_detalhada
    FROM conta_sequencia
    ORDER BY seller_id, mes_referencia
)

SELECT
    mes_referencia,
    seller_id,
    mes_primeira_venda,
    valor_total,
    classificacao_detalhada AS classificacao_final
FROM resultado_final
ORDER BY seller_id, mes_referencia;

