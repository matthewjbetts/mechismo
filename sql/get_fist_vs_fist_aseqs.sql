/*
# fist to fist via blast
SELECT h.id                id_hsp,
       h.pcid,
       h.score,
       h.e_value,

       sa1.id              id_seq1,
       sa2.id              id_seq2,

       sa1.len,
       aseq1.start,
       aseq1.end,
       aseq1._edit_str,

       sa2.len,
       aseq2.start,
       aseq2.end,
       aseq2._edit_str

FROM   Hsp            AS h,

       Seq            AS sa1,
       AlignedSeq     AS aseq1,

       Seq            AS sa2,
       AlignedSeq     AS aseq2

WHERE   sa1.id = h.id_seq1
AND     sa1.source = 'fist'
AND     aseq1.id_aln = h.id_aln
AND     aseq1.id_seq = sa1.id

AND     sa2.id = h.id_seq2
AND     sa2.source = 'fist'
AND     aseq2.id_aln = h.id_aln
AND     aseq2.id_seq = sa2.id
;
*/

# fist to fist via pfam, excluding those with blast hsps
SELECT a_to_g.id_aln,

       0.0, # FIXME - calculate pcid from two aligned sequences
       0,
       a.e_value,

       a.id_seq1,
       a.id_seq2,

       a.len1,
       a.start1,
       a.end1,
       as1._edit_str,

       a.len2,
       a.start2,
       a.end2,
       as2._edit_str,

       'pfam',
       a.ac_src

FROM   (
        SELECT a.*
        FROM   (
                SELECT f.ac_src                            ac_src,

                       s1.id                               id_seq1,
                       s1.len                              len1,
                       fi1.start_seq                       start1,
                       fi1.end_seq                         end1,

                       s2.id                               id_seq2,
                       s2.len                              len2,
                       fi2.start_seq                       start2,
                       fi2.end_seq                         end2,

                       GREATEST(fi1.e_value, fi2.e_value)  e_value


                FROM   Seq         AS s1,
                       FeatureInst AS fi1,
                       Feature     AS f,
                       FeatureInst AS fi2,
                       Seq         AS s2

                WHERE  s1.source = 'fist'
                AND    fi1.id_seq = s1.id
                AND    f.id = fi1.id_feature
                AND    f.source = 'pfam'
                AND    fi2.id_feature = f.id
                AND    s2.id = fi2.id_seq
                AND    s2.source = 'fist'
                AND    s2.id != s1.id
               ) AS a
               LEFT JOIN Hsp as h ON h.id_seq1 = a.id_seq1 AND h.id_seq2 = a.id_seq2
        WHERE  h.id IS NULL
       ) AS a,
       SeqGroup         AS g,
       AlignmentToGroup AS a_to_g,
       AlignedSeq       AS as1,
       AlignedSeq       AS as2

WHERE  g.type = 'pfam'
AND    g.ac = a.ac_src
AND    a_to_g.id_group = g.id
AND    as1.id_aln = a_to_g.id_aln
AND    as1.id_seq = a.id_seq1
AND    as2.id_aln = a_to_g.id_aln
AND    as2.id_seq = a.id_seq2
;
