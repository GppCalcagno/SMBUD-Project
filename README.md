# :card_file_box: System and Method for Big and Unsrtucuted Data
This is the repository for the projects of the Systems and Methods for Big and Unstructured Data (SMBUD) course helds at [Polimi](https://www.polimi.it/).

The purpose of the project is to design and implement different databases which stores bibliographic information on major journals, papers and authors, inspired by already existing systems, such as DBLP. Different aspects of the type of data is highlighted with diffrerent data management technologies:
* Relational Database 
* Graph Database- [Neo4j](https://neo4j.com/)
* Documental Database - [MongoDB](https://www.mongodb.com/it-it)
* Computational Engine - [Spark](https://spark.apache.org/)

For each technology a database is designed, data are extracted from sources (or generated randomly for didactic porpouse) and different query are written to study and learn the used language. A final report (and presentation) is available in which all the phases of the 3 projects are described in detail.

### 1) Graph Database <img src="https://img.shields.io/badge/Neo4j-018bff?&logo=neo4j&logoColor=white">
Neo4j is used to represent with a graph db the main relationship between publications,authors, institution and so on. All the data are taken starting from [DBLP](https://dblp.org/) XML and some records are generated randomly using some python scripts. In the linked folder is present:
 * XML parcer 
 * Dataset 
 * Queries executed and Load Commands 
 
 
 ### 2) Document Database <img src="https://img.shields.io/badge/MongoDB-4EA94B?&logo=mongodb&logoColor=white">
MongoDB is used to represent the main features and data of a collection on documents (citation, sections, figures). Records are uploaded as json using a python script to convert data of the first project from csv to json (text of the documents is generated randomly). In the linked folder is present:
 * Python script to convert data
 * Dataset (queries present in the report)
 
 ### 3) Spark <img src="https://img.shields.io/badge/Apache_Spark-FFFFFF?logo=apachespark&logoColor=#E35A16">
 
 
  

