# Análise de Retenção e Churn de Vendedores (Sellers) com SQL

## 📌 Contexto do Projeto
Em plataformas de e-commerce e marketplaces, a saúde do negócio não depende apenas de atrair novos vendedores, mas de mantê-los ativos e vendendo. Este projeto tem como objetivo mapear o ciclo de vida de cada vendedor, classificando seu status mês a mês para identificar padrões de retenção e evasão (Churn).

## 🎯 O Problema de Negócio
Saber quando um vendedor fez sua primeira venda ou quando deixou de vender é crucial para a estratégia corporativa. Identificar rapidamente um "Churn" permite que o time de negócios atue com campanhas de recuperação antes que o parceiro abandone a plataforma definitivamente.

Este script em SQL resolve esse problema criando um histórico contínuo para cada vendedor, classificando-os nas seguintes categorias estratégicas:
* **Novo:** Mês exato da primeira venda do vendedor.
* **Regular:** Vendedor que realizou vendas no mês atual e também no mês anterior.
* **Recuperado:** Vendedor que estava inativo (Churn) e voltou a vender no mês atual.
* **Churn (1, 2, 3, 4+):** Vendedor que não realizou vendas no mês atual, contabilizando há quantos meses consecutivos ele está inativo.

## 🛠️ Técnicas e Ferramentas Utilizadas
Neste projeto, utilizei **SQL Avançado** para transformar dados transacionais brutos em uma tabela analítica completa. As principais técnicas demonstradas no código incluem:
* **CTEs (Common Table Expressions):** Utilizadas para estruturar a lógica passo a passo, garantindo que o código seja limpo, modular e de fácil manutenção.
* **Cross Join Estratégico:** Geração de uma matriz cruzando todos os meses de operação com todos os vendedores. Isso garante que os meses em que um vendedor não teve vendas não desapareçam da análise, lidando perfeitamente com a ausência de dados.
* **Window Functions:** Uso da função `LAG()` para comparar o status de venda do mês atual com o mês imediatamente anterior.
* **Resolução de Gaps and Islands:** Aplicação avançada da diferença entre dois `ROW_NUMBER()` para criar IDs de grupos. Isso permitiu agrupar e contar com precisão os meses consecutivos em que um vendedor permaneceu no status de inatividade (Churn 1, 2, 3, etc.).

## 🔍 Estrutura Lógica do Código
O script foi desenvolvido seguindo um raciocínio analítico sequencial:
1. Extração de todos os meses de referência únicos da operação.
2. Identificação do mês da primeira venda de cada vendedor isoladamente.
3. Criação de uma linha do tempo contínua por vendedor.
4. Cálculo do valor total vendido (preço + frete) em cada mês.
5. Classificação primária do status (Ativo/Inativo) baseada no faturamento do mês.
6. Contagem de repetições contínuas para detalhar a profundidade do Churn.

## 💡 Aplicações e Insights para o Negócio
Com o resultado gerado por esta query, um time de Dados ou Business Intelligence pode facilmente:
* Construir dashboards dinâmicos (no Power BI, por exemplo) para acompanhar a taxa de retenção e a evolução do Churn mensal.
* Fornecer listas automatizadas de vendedores em "Churn 1" para o time de Marketing disparar e-mails de reengajamento rápidos.
* Avaliar a eficácia das campanhas ao medir a porcentagem de vendedores que mudam do status de "Churn" para "Recuperado".
