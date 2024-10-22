create database restaurante;
use restaurante;

-- drop database restaurante;


create table mesas(
id int primary key,
quant_clientes int default 0,
status_mesa int default 0,
hora_entrada datetime
);

create table pedidos(
id int auto_increment primary key,
id_mesa int,
id_cardapio int,
quantidade int,
valor double
);

create table cardapio(
id int auto_increment primary key,
nome varchar(255),
preco double
);

create table status_pagamento(
id int primary key,
nome varchar(255) NOT NULL
);

create table status_mesa(
id int primary key,
nome varchar(255) NOT NULL
);

create table pagamentos_processados(
id int auto_increment primary key,
id_mesa int,
status_pagamento int,
total_conta double,
tipo_pagamento int,
valor_dinheiro double,
troco double,
hora_pag datetime default now());

-- colocando FK nas tabelas
alter table mesas add constraint fk_status_mesa_mesas foreign key (status_mesa) references status_mesa(id);

alter table pedidos add constraint fk_mesas_pedidos foreign key (id_mesa) references mesas(id);
alter table pedidos add constraint fk_cardapio_pedidos foreign key (id_cardapio) references cardapio(id);

alter table pagamentos_processados add constraint fk_mesa_processados foreign key (id_mesa) references mesas(id);
alter table pagamentos_processados add constraint fk_status_processados foreign key (status_pagamento) references status_pagamento(id);


-- Procedure para ocupação de mesa
DELIMITER $$
CREATE PROCEDURE ocupacao_mesa(
in id_in int, 
in quant_clientes_in int)
BEGIN
	if ((select status_mesa from mesas where id = id_in) = 0) then
		update mesas
        set quant_clientes = quant_clientes_in, status_mesa = 1, hora_entrada = now()
        where id = id_in;
		select 'Mesa adicionada com sucesso';
	else
		select 'Mesa já ocupada';
	end if;
END;

-- Procedure para adicionar itens no cardápio
DELIMITER $$
CREATE PROCEDURE adiciona_itens(
in nome_in varchar(255),
in preco_in double)
BEGIN
	insert into cardapio (nome, preco)
    values (nome_in, preco_in);
END;

-- Procedure para adicionar novo pedido
DELIMITER $$
CREATE PROCEDURE novo_pedido(
in id_mesa_in int, 
in id_cardapio_in int, 
in quantidade_in int)
BEGIN
	select preco into @preco from cardapio where id = id_cardapio_in;
    
    if (id_cardapio_in = (select id from cardapio where id = id_cardapio_in)) then
        if (quantidade_in <> 0) then
            insert into pedidos (id_mesa, quantidade, id_cardapio, valor)
			values (id_mesa_in, quantidade_in, id_cardapio_in, (@preco * quantidade_in));
		else
			select 'Quantidade inválida';
		end if;
	else
		select 'Item do menu inválido';
	end if;		
END;

-- Procedure para processando_pagamento
DELIMITER $$
CREATE PROCEDURE processando_pagamento(in id_mesa_in int, in tipo_pagamento_in int, in valor_dinheiro_in double)
BEGIN
	(select SUM(valor) into @valor from pedidos where id_mesa = id_mesa_in);
    
    if (@valor > 0) then
		if ( (select id from mesas where id = id_mesa_in) = id_mesa_in) then
			if ( (select status_mesa from mesas where id = id_mesa_in) = 1) then
				if (tipo_pagamento_in in (0,1)) then
					if (tipo_pagamento_in = 0) then
						if (valor_dinheiro_in >= @valor) then
							insert into pagamentos_processados (id_mesa, status_pagamento, total_conta, tipo_pagamento, valor_dinheiro, troco)
							values (id_mesa_in, 0, @valor, 0, valor_dinheiro_in, (valor_dinheiro_in - @valor));
							select 'Pagamento feito com sucesso';
						else
							insert into pagamentos_processados (id_mesa, status_pagamento, total_conta, tipo_pagamento, valor_dinheiro, troco)
							values (id_mesa_in, 1, @valor, 0, valor_dinheiro_in, (valor_dinheiro_in - @valor));
							select 'Dinheiro insuficiente';
						end if;
					else
						insert into pagamentos_processados (id_mesa, status_pagamento, total_conta, tipo_pagamento, valor_dinheiro, troco)
						values (id_mesa_in, 0, @valor, 1, 0, 0);
						select 'Pagamento feito com sucesso';
					end if;
				else
					select 'Tipo de pagamento inválido';
				end if;
			else
				select 'Mesa já está vazia';
			end if;
		else
			select 'Número da mesa inválido';
		end if;
	else
        update mesas
		set quant_clientes = 0, status_mesa = 0, hora_entrada = NULL
		where id = id_mesa_in;
		select 'Mesa desocupada com sucesso';
	end if;
END;

-- Trigger para atualizar status_pedido na tabela cozinha 
DELIMITER $$
CREATE TRIGGER trg_desocupa_mesa after insert
on pagamentos_processados
for each row
BEGIN
	update mesas
	set quant_clientes = 0, status_mesa = 0, hora_entrada = NULL
	where id = new.id;
END;

-- inserindo valores nas tabelas abaixo

insert into status_pagamento (id, nome)
values (0, 'Processado'), (1, 'Cancelado');

insert into status_mesa (id, nome)
values (0, 'Vazia'), (1, 'Ocupada');

insert into mesas (id, status_mesa)
values (1,0), (2,0), (3,0), (4,0), (5,0), (6,0), (7,0), (8,0), (9,0), (10,0);

-- Chamando procedures

call ocupacao_mesa(1,6); -- (id, quant_clientes)
call ocupacao_mesa(2,4);
call ocupacao_mesa(3,2);
call ocupacao_mesa(4,6);
call ocupacao_mesa(5,2);
call ocupacao_mesa(6,4);
call ocupacao_mesa(7,3);
call ocupacao_mesa(8,2);


call adiciona_itens('Galinhada',50); -- (nome, preco)
call adiciona_itens('Refrigerante',5);
call adiciona_itens('Cerveja',9);
call adiciona_itens('Pudim',12);
call adiciona_itens('Macarronada',30);
call adiciona_itens('Frango à milanesa',35);


call novo_pedido (1,1,2); -- (id_mesa, id_cardapio, quantidade)
call novo_pedido (1,2,2);
call novo_pedido (2,4,2);
call novo_pedido (3,6,2);
call novo_pedido (5,5,1);
call novo_pedido (6,2,2);
call novo_pedido (6,1,2);

call processando_pagamento(1,0,200); -- (id_mesa, tipo_pagamento, valor_dinheiro)
call processando_pagamento(7,0,0);
