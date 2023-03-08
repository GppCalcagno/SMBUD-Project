from lxml import etree
from datetime import datetime
import csv
import re
import argparse
import random
import string

MAX_NUM_TYPE = 3000

def log_msg(message):
    """Produce a log with current time"""
    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"), message)


def context_iter(dblp_path):
    """Create a dblp data iterator of (event, element) pairs for processing"""
    return etree.iterparse(source=dblp_path, dtd_validation=True, load_dtd=True, events=('start', 'end'))


def clear_element(element):
    """Free up memory for temporary element tree after processing the element"""
    element.clear()
    while element.getprevious() is not None:
        del element.getparent()[0]


def getAttribute(attr, defaultValue = ''):
    if attr and len(attr) > 0:
        return attr[0]
    return defaultValue

def getWord(word):
    return str(word).replace('"','\'').replace('\n', '')


def count_pages(pages):
    """Borrowed from: https://github.com/billjh/dblp-iter-parser/blob/master/iter_parser.py
    Parse pages string and count number of pages. There might be multiple pages separated by commas.
    VALID FORMATS:
        51         -> Single number
        23-43      -> Range by two numbers
    NON-DIGITS ARE ALLOWED BUT IGNORED:
        AG83-AG120
        90210H     -> Containing alphabets
        8e:1-8e:4
        11:12-21   -> Containing colons
        P1.35      -> Containing dots
        S2/109     -> Containing slashes
        2-3&4      -> Containing ampersands and more...
    INVALID FORMATS:
        I-XXI      -> Roman numerals are not recognized
        0-         -> Incomplete range
        91A-91A-3  -> More than one dash
        f          -> No digits
    ALGORITHM:
        1) Split the string by comma evaluated each part with (2).
        2) Split the part to subparts by dash. If more than two subparts, evaluate to zero. If have two subparts,
           evaluate by (3). If have one subpart, evaluate by (4).
        3) For both subparts, convert to number by (4). If not successful in either subpart, return zero. Subtract first
           to second, if negative, return zero; else return (second - first + 1) as page count.
        4) Search for number consist of digits. Only take the last one (P17.23 -> 23). Return page count as 1 for (2)
           if find; 0 for (2) if not find. Return the number for (3) if find; -1 for (3) if not find.
    """
    cnt = 0
    if pages is None:
        return
    for part in re.compile(r",").split(pages):
        subparts = re.compile(r"-").split(part)
        if len(subparts) > 2:
            continue
        else:
            try:
                re_digits = re.compile(r"[\d]+")
                subparts = [int(re_digits.findall(sub)[-1]) for sub in subparts]
            except IndexError:
                continue
            cnt += 1 if len(subparts) == 1 else subparts[1] - subparts[0] + 1
    return "" if cnt == 0 else str(cnt)

def extract_feature(elem, features, include_key=False):
    """Extract the value of each feature"""
    if include_key:
        attribs = {'key': [elem.attrib['key']]}
    else:
        attribs = {}
    for feature in features:
        attribs[feature] = []
    for sub in elem:
        if sub.tag not in features:
            continue
        if sub.tag == 'title':
            text = re.sub("<.*?>", "", etree.tostring(sub).decode('utf-8')) if sub.text is None else sub.text
        elif sub.tag == 'pages':
            text = count_pages(sub.text)
        elif sub.tag == 'author' and sub.text is not None:
            try:
                text = sub.text + '|' + sub.attrib['orcid']
            except:
                text = sub.text
        else:
            text = sub.text
        if text is not None and len(text) > 0:
            attribs[sub.tag] = attribs.get(sub.tag) + [text]
    return attribs


def parse_author_publication_relations(relationship_data, attrib_values, publications_id):
    if len(attrib_values['author']) == 1:
        relationship_data.append([attrib_values['author'][0].split('|')[0], publications_id, 'first'])
    elif len(attrib_values['author']) > 1:
        for i in range(len(attrib_values['author'])):
            if i == 0:
                relationship_data.append([attrib_values['author'][i].split('|')[0], publications_id, 'first'])
            elif i == (len(attrib_values['author']) - 1):
                relationship_data.append([attrib_values['author'][i].split('|')[0], publications_id, 'last'])
            else:
                relationship_data.append([attrib_values['author'][i].split('|')[0], publications_id, 'middle'])


def parse_publication(dblp_path, publication_cnt = 1000000, save_to_csv=False, include_key=False):
    max_article = 0
    max_inpro = 0
    max_incoll = 0
    max_book = 0

    log_msg("PROCESS: Start parsing publications...")
    publications = ['article', 'incollection', 'inproceedings', 'book']
    article_features = ['title', 'author', 'year', 'journal', 'pages', 'ee', 'publisher']
    incollection_features = ['title', 'author', 'year', 'booktitle', 'pages', 'ee', 'publisher']
    inproceeding_features = ['title', 'author', 'year', 'booktitle', 'pages', 'ee', 'publisher']
    book_features = ['title', 'author', 'year', 'isbn', 'pages', 'ee', 'publisher']
    feature = []
    authors_data = set()
    publications_data = []
    relationship_data = []
    publisher_data = set()
    journal_data = set()
    conference_data = set()
    journal_issued_data = []
    conference_issued_data = []
    publisher_issued_data = []
    for _, elem in context_iter(dblp_path):
        if elem.tag in publications:        
            if elem.tag == 'article':
                if max_article > MAX_NUM_TYPE:
                    continue
                feature = article_features
                max_article = max_article + 1
            elif elem.tag == 'incollection':
                if max_incoll > MAX_NUM_TYPE:
                    continue
                feature = incollection_features
                max_incoll = max_incoll + 1
            elif elem.tag == 'inproceedings':
                if max_inpro > MAX_NUM_TYPE:
                    continue
                feature = inproceeding_features
                max_inpro = max_inpro + 1
            elif elem.tag == 'book':
                if max_book > MAX_NUM_TYPE:
                    continue
                feature = book_features
                max_book = max_book + 1
            else: 
                continue
            attrib_values = extract_feature(elem, feature, include_key)

            if not attrib_values['title'] or not attrib_values['author']:
                if elem.tag == 'article':
                    max_article = max_article - 1
                elif elem.tag == 'incollection':
                    max_incoll = max_incoll - 1
                elif elem.tag == 'inproceedings':
                    max_inpro = max_inpro - 1
                elif elem.tag == 'book':
                    max_book = max_book - 1
                continue

            if not save_to_csv:
                log_msg("LOG: Successfully entity \"{}\". Attributes \"{}\".".format(elem.tag, attrib_values))
            else:
                authors_data.update(a for a in attrib_values['author'])
                publications_id = getAttribute(attrib_values['ee'], getWord(attrib_values['title'][0]) + '_' + getAttribute(attrib_values['year']))
                try:
                    publications_data_line = publications_id + '|' + getWord(attrib_values['title'][0]) + '|' + getAttribute(attrib_values['year']) + '|' + getAttribute(attrib_values['pages'], '0') + '|' + getAttribute(attrib_values['isbn']) + '|' + getAttribute(attrib_values['publisher'])+ '|' + elem.tag
                except:
                    publications_data_line = publications_id + '|' + getWord(attrib_values['title'][0]) + '|' + getAttribute(attrib_values['year']) + '|' + getAttribute(attrib_values['pages'], '0') + '|' + getAttribute('') + '|' + getAttribute(attrib_values['publisher'])+ '|' + elem.tag    
                publications_data.append(publications_data_line.split('|'))
                parse_author_publication_relations(relationship_data, attrib_values, publications_id)
                
                publisher_data.update(a for a in attrib_values['publisher'])
                if attrib_values['publisher']:
                    publisher_data_line = publications_id + '|' + getAttribute(attrib_values['publisher'])
                    publisher_issued_data.append(publisher_data_line.split('|'))
                if elem.tag == 'article':
                    journal_data.update(a for a in attrib_values['journal'])
                    journal_issued_data_line = publications_id + '|' + getAttribute(attrib_values['journal'])
                    journal_issued_data.append(journal_issued_data_line.split('|'))
                elif elem.tag == 'inproceedings':
                    conference_data.update(a for a in attrib_values['booktitle'])
                    conference_issued_data_line = publications_id + '|' + getAttribute(attrib_values['booktitle'])
                    conference_issued_data.append(conference_issued_data_line.split('|'))
                
            publication_cnt = publication_cnt - 1
            #print("tot" + str(publication_cnt)+ " article:" + str(max_article) +" book: "+str(max_book)+ " Inpro"+ str(max_inpro)+ "inColl:" + str(max_incoll))
            if publication_cnt == 0:
                break

        clear_element(elem)
    
    authors_data_csv = [a.split('|') for a in authors_data]
    
    create_file_with_header('dataset/authors.csv', ['author_name', 'orcid'], authors_data_csv, notSet=True)
    create_file_with_header('dataset/publications.csv', ['id', 'title', 'year', 'pages', 'isbn', 'publisher', ' doc_type'], publications_data, notSet=True)
    create_file_with_header('dataset/relationship.csv', ['author_name', 'id', 'author_order'], relationship_data, notSet=True)
    create_file_with_header('dataset/journals.csv', ['name'], journal_data)
    create_file_with_header('dataset/conferences.csv', ['name'], conference_data)
    create_file_with_header('dataset/publisher.csv', ['name'], publisher_data)
    create_file_with_header('dataset/journals_relationship.csv', ['id', 'name'], journal_issued_data, notSet=True)
    create_file_with_header('dataset/conferences_relationship.csv', ['id', 'name'], conference_issued_data, notSet=True)
    create_file_with_header('dataset/publisher_relationship.csv', ['id', 'name'], publisher_issued_data, notSet=True)

    log_msg("FINISHED...")


def create_file_with_header(file_path, headers, data, notSet=False):
    log_msg("LOG: Creating file \"{}\". headers \"{}\".".format(file_path, headers))
    f = open(file_path, 'w', newline='', encoding='utf8')
    writer = csv.writer(f, delimiter='|')
    writer.writerow(headers)
    if notSet:
        writer.writerows(data)
    else:
        writer.writerows([d] for d in data)
    f.close()


def main():
    dblp_path = 'dataset/dblp.xml'

    parser = argparse.ArgumentParser()
    parser.add_argument("-number", help="Number of publications")
    publication_cnt = MAX_NUM_TYPE * 4
    args = parser.parse_args()
    if args.number :
        publication_cnt = int(args.number)

    try:
        context_iter(dblp_path)
        log_msg("LOG: Successfully loaded \"{}\".".format(dblp_path))
    except IOError:
        log_msg("ERROR: Failed to load file \"{}\". Please check your XML and DTD files.".format(dblp_path))
        exit()
    
    parse_publication(dblp_path, publication_cnt, save_to_csv=True, include_key=False)

if __name__ == '__main__':
    main()