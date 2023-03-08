//Query1: Top 5 keywords linked to publications contained in a journal, written by authors working in an institution located in $country
MATCH (pub:Publication)-[:CONTAINED_IN]->(j:Journal)
WITH pub
MATCH (inst:Institution)<-[:AFFILIATING]-(aut:Author)-[:HAS_WRITTEN]->(pub)-[:HAS]->(kw:Keyword)
WHERE inst.country = $country
WITH kw, COUNT(DISTINCT pub) as num_pub
RETURN kw.word, num_pub
ORDER BY num_pub DESC
LIMIT 5

//Query2: Top 5 authors with more than $num citations of their publications.
MATCH (aut:Author)-[:HAS_WRITTEN]->()<-[c:CITES]-(pub_cit:Publication)
WITH aut.name as author, COUNT(DISTINCT pub_cit) AS num_cit
WHERE num_cit > $num
RETURN author, num_cit
ORDER BY num_cit DESC
LIMIT 5

//Query3: Top 5 authors having more than $num papers taken from a conference.
MATCH (aut:Author)-[:HAS_WRITTEN]->(p:Publication)-[:HELD]->(conf:Conference)
WITH aut.name as author, COUNT(DISTINCT conf) AS num_conf
WHERE num_conf > $num
RETURN author, num_conf
ORDER BY num_conf DESC, author
LIMIT 5

//Query4: The 5 pairs of authors, with the greatest age difference, who wrote together a paper linked to the conference $name.
MATCH (p:Publication)-[:HELD]->(c:Conference{name:$name})
WITH p
MATCH (a1:Author)-[w1:HAS_WRITTEN]->(p)<-[w2:HAS_WRITTEN]-(a2:Author)
WHERE a1.year_of_birth > a2.year_of_birth
WITH a1, a2, (a1.year_of_birth - a2.year_of_birth) as AgeDifference, p
RETURN a1.name, a2.name, AgeDifference, p.doi
ORDER BY AgeDifference DESC
LIMIT 5

//Query5:  Pairs of conferences in which the papers of the second are cited, even indirectly, by the papers of the first, ordered by number of citations.
MATCH (c1:Conference)<-[:HELD]-(p1:Publication)
MATCH (c2:Conference)
WHERE c1 <> c2 AND c1.year >= c2.year
WITH c1, c2, p1
MATCH (p1)-[r1:CITES*1..3]->(p2)-[:HELD]->(c2)
RETURN c1.name,c1.year,c2.name,c2.year,count(r1) AS ConferenceCitation
ORDER BY ConferenceCitation DESC
LIMIT 5

//Query6: Top 3 publishers of book written by authors with average age between 30 and 40
MATCH (p2:Publisher)<-[:PUBLISHED_BY]-(p1:Publication{doc_type:"book"})<-[:HAS_WRITTEN]-(a:Author)
WITH p2 AS publisher, p1 AS publication, avg(date().year - a.year_of_birth)
AS avgAge
WHERE avgAge > 30 AND avgAge < 40
WITH publisher, COUNT(DISTINCT publication) AS num_publications
RETURN publisher.name, num_publications
ORDER BY num_publications DESC
LIMIT 3

//Query7: Distribution of publication types in the year $year
OPTIONAL MATCH (p1:Publication{doc_type:"article", year:$year})
WITH COUNT(p1) AS article
OPTIONAL MATCH (p2:Publication{doc_type:"book", year:$year})
WITH COUNT(p2) AS book, article
OPTIONAL MATCH (p3:Publication{doc_type:"incollection", year:$year})
WITH COUNT(p3) AS incollection, article, book
OPTIONAL MATCH (p4:Publication{doc_type:"inproceedings", year:$year})
WITH COUNT(p4) AS inproceeding, article, book,
incollection
WITH (article + book + incollection + inproceeding) AS tot, article, book,
incollection, inproceeding
RETURN toFloat(article)/tot * 100 AS percentageArticle,
toFloat(book)/tot * 100 AS percentageBook,
toFloat(incollection)/tot * 100 AS percentageIncollection,
toFloat(inproceeding)/tot * 100 AS percentageInproceeding

//Query8: Find the keywords of the 3 publications that are cited the most and that are written by an author working in a top-5 institution in the world.
MATCH (p1:Publication)-[:CITES]->(p2:Publication)
MATCH (p2:Publication)-[:HAS]->(k:Keyword)
MATCH (p2)<-[:HAS_WRITTEN]-()-[:AFFILIATING]->(inst:Institution)
WITH inst.world_rank AS wr, k, p2, p1
WHERE wr <= 5
RETURN k.word AS keyword, p2.title AS publication, COUNT(DISTINCT p1)
AS num_citations, wr
ORDER BY num_citations DESC, wr LIMIT 3

//Query9: Find the authors working in a $country institution, who wrote a book in $year with the greatest number of pages.
MATCH (aut:Author)-[:HAS_WRITTEN]->(pub:Publication{doc_type:"book",year:$year})
MATCH (aut)-[:AFFILIATING]->(inst:Institution{country:$country})
WITH pub, aut, inst
RETURN aut.name AS author, inst.name AS institution, pub.title AS publication,
pub.pages AS pages
ORDER BY pages DESC
LIMIT 3

//Query10: 5 publications of an year [2010-2020] contained in a journal, that are written by the greatest number of authors coming from institutions located in different countries.
MATCH (pub:Publication)-[:CONTAINED_IN]->(j:Journal)
MATCH (pub)<-[:HAS_WRITTEN]-()-[:AFFILIATING]->(inst:Institution)
WITH COUNT(DISTINCT inst.country) AS num_countries, pub
WHERE pub.year > 2010 AND pub.year < 2020
RETURN num_countries, pub.title AS publication, pub.year AS year
ORDER BY num_countries DESC LIMIT 5

//Query11: Find the conferences related to publications which are written by at least one author working in a top-3 national rank institution of Milan.
MATCH (conf:Conference)<-[:HELD]-(pub:Publication)<-[:HAS_WRITTEN]-(aut:Author)-[:AFFILIATING]->(inst:Institution)
WHERE inst.national_rank <= 3 AND inst.name CONTAINS 'Milan'
RETURN conf.name AS conference, inst.name AS institution,
inst.national_rank AS nr

//Query12: Find the number of authors under 40 working in the top 5 universities in the world.
MATCH (i:Institution)
WHERE i.world_rank <= 5
WITH i
MATCH (a:Author)-[:AFFILIATING]->(i)
WITH (date().year - a.year_of_birth) < 40 AS age, i
WITH sum(toInteger(age)) AS num_authors, i
RETURN i.name AS institution, num_authors
ORDER BY num_authors DESC

//Query13: Minimum path between universities with the greatest number of produced papers and the minimum path between universities with the smallest number of produced papers
//take the relation as bidirectional, with *2 we take only the paper
//written by an author of that institution
MATCH (i:Institution)-[*1..2]-(p:Publication)
WITH I, COUNT( distinct p) AS pubnum
ORDER BY pubnum DESC
WITH collect(i) as list
MATCH (a:Institution {name: list[0].name}),
(b:Institution {name: list[1].name}),
p1 = shortestPath((a)-[*1..8]-(b))
MATCH (c:Institution {name: list[size(list)-2].name}),
(d:Institution {name: list[size(list)-1].name}),
p2 = shortestPath((c)-[*1..8]-(d))
WHERE length(p2) > 1 AND length(p1) > 1
return a.name, b.name, p1, c.name, d.name, p2



