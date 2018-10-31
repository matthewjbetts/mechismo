SET @min_n_resres = 30;

SELECT   0         isa_p,
         0         lf_p,
         0         pcid_p,
         0         frag_p,
         0         aj_p,
         0         fj_p,
         0         n_p,
         0         isa_c,
         0         lf_c,
         0         pcid_c,
         0         frag_c,
         0         aj_c,
         0         fj_c,
         COUNT(id) n_c
FROM     Contact
WHERE    isa_group IS FALSE
AND      n_clash = 0
AND      n_resres >= @min_n_resres

UNION
 
SELECT   parent.isa_group              isa_p,
         ROUND(parent.lf,1)            lf_p,
         ROUND(parent.pcid,1)          pcid_p,
         parent.same_frag              frag_p,
         ROUND(parent.aln_jaccard,1)   aj_p,
         ROUND(parent.full_jaccard,1)  fj_p,

         COUNT(DISTINCT(parent.id))    n_p,

         child.isa_group               isa_c,
         ROUND(child.lf,1)             lf_c,
         ROUND(child.pcid,1)           pcid_c,
         child.same_frag               frag_c,
         ROUND(child.aln_jaccard,1)    aj_c,
         ROUND(child.full_jaccard,1)   fj_c,

         COUNT(child.id)                n_c

FROM     Contact       AS parent,
         ContactMember AS member,
         Contact       AS child

WHERE    parent.n_clash = 0
AND      parent.n_resres >= @min_n_resres
AND      member.id_parent = parent.id
AND      child.id = member.id_child
AND      child.n_clash = 0
AND      child.n_resres >= @min_n_resres

GROUP BY parent.isa_group,
         parent.lf,
         parent.pcid,
         parent.same_frag,
         parent.aln_jaccard,
         parent.full_jaccard,

         child.isa_group,
         child.lf,
         child.pcid,
         child.same_frag,
         child.aln_jaccard,
         child.full_jaccard
;
