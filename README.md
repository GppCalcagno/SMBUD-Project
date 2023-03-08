# :card_file_box: System and Method for Big and Unsrtucuted Data
This is the repository for the projects of the Systems and Methods for Big and Unstructured Data (SMBUD) course helds at [Polimi](https://www.polimi.it/).

The purpose of the project is to design and implement different databases which stores bibliographic information on major journals, papers and authors, inspired by already existing systems, such as DBLP. Different aspects of the type of data is highlighted with diffrerent data management technologies:
* Relational Database 
* Graph Database- [Neo4j](https://neo4j.com/)
* Documental Database - [MongoDB](https://www.mongodb.com/it-it)
* Computational Engine - [Spark](https://spark.apache.org/)

For each technology a database is designed, data are extracted from sources (or generated randomly for didactic porpouse) and different query are written to study and learn the used language. 

### 1) Graph Database <img src="https://img.shields.io/badge/Neo4j-018bff?&logo=neo4j&logoColor=white">
 Neo4j is used to represent with a graph db the main relationship between publications,authors, institution and so on. All the data are taken starting from [DBLP](https://dblp.org/) XML and some records are generated randomly using some python scripts. In the linked folder is present:
 * XML parcer 
 * Dataset 
 * Queries executed

