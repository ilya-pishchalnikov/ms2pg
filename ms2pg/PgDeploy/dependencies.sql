declare @iteration int = 1;

drop table if exists #dependencies;

create table #dependencies (
    parent_object varchar (255)
    ,child_object varchar (255)
    , index x (parent_object, child_object)
);

drop table if exists #deploy_order;

create table #deploy_order (
        deploy_order int identity (1, 1) primary key clustered
      , object_name varchar (255)
      , iteration int
      , index x (object_name)
);

insert into #dependencies (parent_object, child_object)
select  
    object_schema_name (object_id) + '.' + object_name (object_id) as parent_object
    , object_schema_name (referenced_major_id) + '.' + object_name (referenced_major_id) as child_object
from sys.sql_dependencies
union
select object_schema_name (parent_object_id) + '.' + object_name (parent_object_id) as parent_object
    , object_schema_name (referenced_object_id) + '.' + object_name (referenced_object_id)  as child_object
from sys.foreign_keys
;

insert into #deploy_order (object_name, iteration)
select  object_schema_name (object_id) + '.' + object_name (object_id), @iteration
from sys.objects o
where  not exists (select * from #dependencies where object_schema_name (object_id) + '.' + object_name (object_id) = parent_object)
  and  not exists (select * from #dependencies where object_schema_name (object_id) + '.' + object_name (object_id) = child_object)
  and o.is_ms_shipped = 0
  and type in ('FN', 'P', 'TF', 'TR', 'U', 'V');

while exists (select * from #dependencies)
begin
    set @iteration += 1;
    insert into #deploy_order (object_name, iteration)
    select distinct child_object, @iteration
    from #dependencies d
    where not exists (
            select *
            from #dependencies d1
            where d1.parent_object = d.child_object
        )
    order by child_object;

    if @@rowcount = 0 break;

    delete d 
    from #dependencies d
    where exists (
            select *
            from #deploy_order o
            where d.child_object = o.object_name
        )
    ;
end;



select * from #deploy_order;