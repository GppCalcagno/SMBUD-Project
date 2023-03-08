//1.1-load_authors
LOAD CSV WITH HEADERS FROM 'file:///author.csv' AS row FIELDTERMINATOR "|" 
WITH row WHERE row.name IS NOT NULL
MERGE (a:Author {
    name: row.name, 
    orcid: row.orcid,
    year: row.year_of_birth,
    month: row.month_of_birth
});

//1.2-load_conferences
LOAD CSV WITH HEADERS FROM 'file:///conferences.csv' AS row FIELDTERMINATOR "|" 
WITH row WHERE row.name IS NOT NULL
MERGE (con:Conference {
    name: row.name, 
    year: toIntegerOrNull(row.year)
});

//1.3-load_institutions
LOAD CSV WITH HEADERS FROM 'file:///institution.csv' AS row FIELDTERMINATOR '|'
WITH row WHERE row.institution IS NOT NULL
CREATE (inst:Institution {
    name: row.institution,
    country: row.country,
    national_ranking: toIntegerOrNull(row.national_rank),
    world_ranking: toIntegerOrNull(row.world_rank)
});

//1.4-load_journals
LOAD CSV WITH HEADERS FROM 'file:///journals.csv' AS row
WITH row WHERE row.name IS NOT NULL
MERGE (j:Journal {
    name: row.name
});

//1.5-load_pubblications
LOAD CSV WITH HEADERS FROM 'file:///publications.csv' AS row FIELDTERMINATOR '|'
CREATE (p:Publication {
    doc_type: row.doc_type,
    doi: row.id,
    isbn: row.isbn, 
    pages: toIntegerOrNull(coalesce(row.pages, '')), 
    title: row.title,
    year: toIntegerOrNull(coalesce(row.year, ''))
});

//1.6-load_publishers
LOAD CSV WITH HEADERS FROM 'file:///publisher.csv' AS row
WITH row WHERE row.name IS NOT NULL
MERGE (ps:Publisher {
    name: row.name
});

//2.1-load_citations
LOAD CSV WITH HEADERS FROM "file:///citationFAKE.csv" AS row FIELDTERMINATOR "|" 
MATCH (p1:Publication{doi:row.document})
MATCH (p2:Publication{doi:row.cite})
CREATE (p1)-[:CITES]->(p2)

//2.2-load_publication->conferences
LOAD CSV WITH HEADERS FROM "file:///conferences_relationship.csv" AS row FIELDTERMINATOR "|"
MATCH (p:Publication{doi:row.id})
MATCH (c:Conference{name:row.name})
CREATE (p)-[:HELD]->(c)

//2.3-load_publications->journals
LOAD CSV WITH HEADERS FROM "file:///journals_relationship.csv" AS row FIELDTERMINATOR "|"
MATCH (p:Publication{doi:row.id})
MATCH (j:Journal{name:row.name})
CREATE (p)-[:CONTAINED_IN]->(j)

//2.4-load_keywords 
LOAD CSV WITH HEADERS FROM "file:///keywords.csv" AS row FIELDTERMINATOR ";"
MATCH (p:Publication {doi: row.pubID})
MERGE (k:Keyword {word: row.keyword})
MERGE (p)-[:HAS]->(k)

//2.5-load_publications->publisher
LOAD CSV WITH HEADERS FROM "file:///publisher_relationship.csv" AS row FIELDTERMINATOR "|"
MATCH (publc:Publication{doi:row.id})
MATCH (publs:Publisher{name:row.name})
CREATE (publc)-[:PUBLISHED_BY]->(publs)

//2.6-load_author->university
LOAD CSV WITH HEADERS FROM "file:///work_rel.csv" AS row FIELDTERMINATOR "|"
MATCH (a:Author {name: row.name})
MATCH (i:Institution {name: row.university})
CREATE (a)-[:WORKS_IN]->(i)

//2.7-load_author->publication
LOAD CSV with headers from "file:///relationship.csv" AS row FIELDTERMINATOR "|" 
MATCH (a:Author{name:row.author_name})
MATCH (p:Publication{doi:row.id})
CREATE (a)-[:HAS_WRITTEN{order:row.author_order}]->(p)

//2.8-load_editors_relationship
LOAD CSV WITH HEADERS FROM "file:///editors_relationship.csv" AS row FIELDTERMINATOR "|"
MATCH (p:Publication {doi: row.doi})
MERGE (e:Editor {name: row.editor})
MERGE (e)-[:EDITED]->(p)

//2.9-load_editor_authors_relationship
LOAD CSV WITH HEADERS FROM "file:///editor_authors_relationship.csv" AS row FIELDTERMINATOR "|"
MATCH (p:Publication {doi: row.doi})
MATCH (a:Author {name: row.editor})
MERGE (a)-[:EDITED]->(p)
SET a:Editor