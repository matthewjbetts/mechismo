SET @min_n_resres = 30;

SELECT a.*
FROM   Contact AS a LEFT JOIN ContactMember AS b ON b.id_child = a.id
WHERE  a.isa_group IS FALSE
AND    a.n_clash = 0
AND    a.n_resres >= @min_n_resres
AND    b.id_parent IS NULL
;
