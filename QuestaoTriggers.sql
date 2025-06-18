Crie a base de dados a seguir:

SerHumano (Matricula, Nome, Endereco, Salario)

Motorista (MotMat, Cnh)
MotMat referencia SerHumano

Cobrador (CobMat, CargaHoraria) 
CobMat referencia SerHumano

Tipo (Id, Descricao, Preco)

Pagamento (Registro, IdTipo, MatMot, MatCob, Dia, Mês, Ano)
IdTipo referencia Tipo
MatMot referencia Motorista
MatCob referencia Cobrador

Faturado (MatMotor, MatCbd, DiaD, MesM, AnoA, TotalDia)

ControleEndereco (Chave, Categoria, Qtd)
Recados (Numero, Msg)

- A tabela 'Tipo' guarda se o tipo de pagamento foi de Passagem inteira ou só Meia passagem. Assuma que o valor de inteira é 4,00 e meia é 2,00.

- 'C'ontroleEndereço' guarda a quantidade de pessoas que moram em Rua e em Avenidas (supondo que só existam essas duas categorias de endereço);

- 1) Crie o trigger que adiciona uma tupla na tabela recados confirmando a inserção de um novo motorista;

CREATE TRIGGER q01 -- Cria um trigger chamado q01
AFTER INSERT ON motorista -- Será executado após uma inserção na tabela motorista
FOR EACH ROW -- Para cada linha inserida
DECLARE
    indice INT; -- Declara uma variável inteira chamada indice
BEGIN
    -- Conta quantos registros existem atualmente na tabela Recados e armazena em indice
    SELECT COUNT (*) INTO Indice FROM Recados;
    -- Insere um novo recado com o próximo índice e uma mensagem informando a inserção de um novo motorista
    INSERT INTO Recados VALUES (Indice + 1, 'Novo motorista inserido');
END;

- 2) Escreva o trigger que, cada vez que é feito um pagamento, é acionada a ação de somar o valor que foi pago ao total do dia, da tabela Faturado. O trigger deve fazer o tratamento caso o pagamento seja de passagem Inteira, ou se for Meia passagem.

CREATE TRIGGER q02 -- Cria um trigger chamado q02
AFTER INSERT ON PAGAMENTO -- Será executado após uma inserção na tabela PAGAMENTO
FOR EACH ROW -- Para cada linha inserida
DECLARE
    pagou NUMERIC(8,2); -- Declara uma variável para armazenar o valor pago
BEGIN
    -- Descobre quanto foi pago buscando o preço do tipo de pagamento relacionado ao novo registro
    SELECT t.preco INTO pagou
    FROM tipo t
    WHERE t.id = new.idtipo;

    -- Atualiza a tabela faturado, somando o valor pago ao total do dia correspondente
    UPDATE faturado f
    SET totaldia = totaldia + pagou
    WHERE f.matmotor = new.matmot
    AND f.matcbd = new.matcob
    AND f.diad = new.dia
    AND f.mesm = new.mes
    AND f. anoa = new.ano;

    -- Caso não exista uma linha correspondente em faturado, seria necessário inserir uma nova linha (não implementado aqui)
END;

- 3) Crie um único trigger que avalia certos parâmetros quando é feita a inserção de um ser humano, e emite mensagens controladoras na tabela Recados: - Se o salário for menor do que 1000.00, o trigger insere um recado informando que o valor do salário é inapropriado e desfaz a operação;

- Se o endereço for uma rua (new.Endereco LIKE...), insira o recado avisando que a pessoa mora numa rua, se for numa avenida, insira o recado de que o ser humano mora numa avenida, e para todos os outros casos, informe que a pessoa não mora nem em rua e nem em avenida.

- Depois dos tratamentos acima, se a ação não foi abortada pelo salário abaixo de 1000, o trigger adiciona em recados a mensagem avisando que a operação
foi concluída com sucesso e confirma a operação;

CREATE TRIGGER q03 -- Cria um trigger chamado q03
AFTER INSERT ON SerHumano -- Será executado após uma inserção na tabela SerHumano
FOR EACH ROW -- Para cada linha inserida
DECLARE
    Indice INT; -- Declara uma variável inteira chamada Indice
BEGIN
    -- Verifica se o salário do novo registro é menor que 1000
    IF new.salario < 1000 THEN
        BEGIN
            PRINT ('Salário inapropriado'); -- Exibe uma mensagem (nem todos os SGBDs suportam PRINT em triggers)
            ROLLBACK; -- Cancela a transação
        END;
    ELSE
    BEGIN
        -- Conta quantos registros existem atualmente na tabela Recados e armazena em Indice
        SELECT COUNT(*) INTO Indice FROM Recados;
        -- Verifica se o endereço contém 'Rua'
        IF new.Endereco LIKE '%Rua%' THEN
            INSERT INTO Recados VALUES (Indice + 1, 'Mora em rua');
        -- Se não, verifica se contém 'avenida'
        ELSIF new.endereco LIKE '%avenida%' THEN
            INSERT INTO recados VALUES (Indice + 1, 'Mora em avenida');
        ELSE
            -- Caso não contenha nem 'Rua' nem 'avenida'
            INSERT INTO Recados VALUES (Indice + 1, 'Não mora nem em rua e nem em avenida');
        END IF;
        -- Insere um recado informando que a operação foi concluída
        INSERT INTO recados VALUES (Indice + 1, 'Operação concluída com sucesso');
        COMMIT; -- Confirma a transação (nem todos os SGBDs permitem COMMIT/ROLLBACK dentro de triggers)
    END;
END;

- 4) Escreva o trigger que verifica a atualização do salário de um ser humano. 
    Caso o novo salário seja menor que o anterior, deve ser calculada a média salarial 
    dos funcionários da mesma função que esta pessoa (cobrador ou motorista) 
    e deve ser incluída em Recados uma tupla informando “O salário atual é menor que o anterior. A média salarial
            
CREATE TRIGGER q04 -- Cria um trigger chamado q04
AFTER UPDATE ON serhumano -- Será executado após atualização na tabela serhumano
REFERENCING OLD AS amarelo NEW AS bacon -- Define aliases para os registros antigo (amarelo) e novo (bacon)
FOR EACH ROW -- Para cada linha atualizada
DECLARE -- Corrigido de DECLAERE para DECLARE
    Indice INT; -- Variável para armazenar o índice de recados
    Media NUMERIC(10,2); -- Variável para armazenar a média salarial
    cargo INT; -- Variável para armazenar a contagem de motoristas
BEGIN
    -- Verifica se o salário novo é menor que o antigo
    IF bacon.salario < amarelo.salario THEN
        -- Conta quantos motoristas possuem a matrícula do registro atualizado
        SELECT COUNT(*) INTO cargo
        FROM Motorista m
        WHERE m.motmat = bacon.matricula; -- Usando bacon.matricula (registro novo)

        IF cargo = 1 THEN
            -- Calcula a média salarial dos motoristas com a matrícula correspondente
            SELECT AVG(h.salario) INTO media
            FROM motorista m, serhumano h
            WHERE m.motmat = h.matricula
            AND m.motmat = bacon.matricula;
        ELSE
            -- Calcula a média salarial dos cobradores com a matrícula correspondente
            SELECT AVG(h.salario) INTO media
            FROM cobrador c, serhumano h
            WHERE c.cobmat = h.matricula
            AND c.cobmat = bacon.matricula;
        END IF;

        -- Conta quantos recados existem atualmente
        SELECT COUNT(*) INTO Indice FROM recados;
        -- Insere um novo recado informando sobre a redução salarial e a média salarial
        INSERT INTO recados VALUES (Indice + 1, 
            'O salário atual é menor que o anterior. A média salarial é ' || media);
            -- Use CONCAT(media) se estiver usando MySQL
    END IF;
END;

- 5) Crie o trigger que verifica os endereços dos seus funcionários. Se alguém está sendo inserido, deletado ou o endereço está sendo atualizado, é preciso verificar a categoria e incrementar ou decrementar a quantidade de acordo com
o evento ocorrido. (Você vai atualizar na tabela ControleEndereco)

CREATE TRIGGER q05 -- Cria um trigger chamado q05
AFTER INSERT OR DELETE OR UPDATE ON serhumano -- Será executado após inserção, deleção ou atualização em serhumano
FOR EACH ROW -- Para cada linha afetada
BEGIN
    -- Se for uma inserção
    IF INSERTING THEN
        -- Se o endereço contém 'Rua'
        IF NEW.endereco LIKE '%Rua%' THEN
            UPDATE controleendereco c
            SET qtd = qtd + 1
            WHERE c.categoria = 'Rua'; -- Corrigido WHHERE para WHERE
        ELSE
            UPDATE controleendereco c
            SET qtd = qtd + 1
            WHERE c.categoria = 'Avenida';
        END IF;
    -- Se for uma deleção
    ELSIF DELETING THEN
        -- Se o endereço contém 'Rua'
        IF OLD.endereco LIKE '%Rua%' THEN -- Corrigido new para OLD
            UPDATE controleendereco c
            SET qtd = qtd - 1
            WHERE c.categoria = 'Rua'; -- Corrigido UPDDATE para UPDATE
        ELSE
            UPDATE controleendereco c
            SET qtd = qtd - 1
            WHERE c.categoria = 'Avenida';
        END IF;
    -- Se for uma atualização
    ELSE
        -- Se o novo endereço contém 'Rua'
        IF NEW.endereco LIKE '%Rua%' THEN
            UPDATE controleendereco c
            SET qtd = qtd + 1
            WHERE c.categoria = 'Rua';
            UPDATE controleendereco c
            SET qtd = qtd - 1
            WHERE c.categoria = 'Avenida';
        ELSE
            UPDATE controleendereco c
            SET qtd = qtd + 1
            WHERE c.categoria = 'Avenida';
            UPDATE controleendereco c
            SET qtd = qtd - 1
            WHERE c.categoria = 'Rua';
        END IF;
    END IF;
END;