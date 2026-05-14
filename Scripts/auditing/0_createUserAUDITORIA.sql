alter session set "_ORACLE_SCRIPT" = true;
create user AUDITORIA identified by AUDITORIA123 quota unlimited on USERS;
grant connect, resource to AUDITORIA;
grant create any trigger to AUDITORIA;

grant select, insert, update, delete on ALFA.HPRODUTO to AUDITORIA;
grant select, insert, update, delete on ALFA.HCANAL to AUDITORIA;
grant select, insert, update, delete on ALFA.HLOJA to AUDITORIA;
grant select, insert, update, delete on ALFA.HSKU to AUDITORIA;
grant select, insert, update, delete on ALFA.HVENDA to AUDITORIA;
grant select, insert, update, delete on ALFA.HITEM_VENDA to AUDITORIA;

COMMIT;
