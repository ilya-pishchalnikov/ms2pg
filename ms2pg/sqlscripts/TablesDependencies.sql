with cte_tables_size as (
		select p.object_id,
			sum (a.total_pages) total_pages, 
			max (p.rows) as row_count
		from sys.partitions p
		inner join sys.allocation_units a on a.container_id = p.partition_id
		group by p.object_id
	)
, cte_dependencies as 
	(
		select
			s1.object_id as table_object_id,
			s1.row_count as referenced_row_count,
			s1.total_pages as referenced_total_pages,
			f.parent_object_id,
			f.referenced_object_id,
			f.name foreign_key_name,
			s.row_count as parent_row_count,
			s.total_pages as parent_total_pages,
			s.row_count * s.row_count as total_combinations,
			string_agg (cast (cp.name as varchar(max)), ', ') as parent_columns,
			string_agg (cast (cr.name as varchar(max)), ', ') as referenced_columns
		from cte_tables_size s1
		left join sys.foreign_keys f on f.referenced_object_id = s1.object_id 
		left join cte_tables_size s on s.object_id = f.parent_object_id
		left join sys.foreign_key_columns fkc on fkc.constraint_object_id = f.object_id
		left join sys.columns cp on cp.object_id = fkc.parent_object_id and cp.column_id = fkc.parent_column_id
		left join sys.columns cr on cr.object_id = fkc.referenced_object_id and cr.column_id = fkc.referenced_column_id
		group by s1.object_id, s1.row_count, s1.total_pages, f.parent_object_id, f.name, s.row_count, s.total_pages, f.referenced_object_id 
	)

select
	object_schema_name (table_object_id) + '.' + object_name (table_object_id) as table_name,
	object_schema_name (referenced_object_id) + '.' + object_name (referenced_object_id) as referenced_table_name,
	referenced_total_pages,
	referenced_row_count,
	foreign_key_name,
	parent_row_count,
	parent_total_pages,
	total_combinations,
	parent_columns,
	referenced_columns
from cte_dependencies
order by referenced_total_pages desc



