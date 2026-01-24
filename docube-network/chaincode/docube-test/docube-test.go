/*
 * Docube Test Chaincode
 * Simple chaincode for testing AdminOrg write / UserOrg read-only permissions
 *
 * Functions:
 *   - CreateDoc (write) - Only AdminOrg should succeed
 *   - ReadDoc (query) - Both AdminOrg and UserOrg should succeed
 *   - GetAllDocs (query) - Both AdminOrg and UserOrg should succeed
 *   - UpdateDoc (write) - Only AdminOrg should succeed
 *   - DeleteDoc (write) - Only AdminOrg should succeed
 */

package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

// SmartContract provides functions for managing documents
type SmartContract struct {
	contractapi.Contract
}

// Document represents a simple document structure
type Document struct {
	ID        string `json:"ID"`
	Title     string `json:"Title"`
	Content   string `json:"Content"`
	Owner     string `json:"Owner"`
	Timestamp string `json:"Timestamp"`
}

// InitLedger adds sample documents to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	docs := []Document{
		{ID: "doc1", Title: "Sample Document 1", Content: "Content of doc 1", Owner: "Admin", Timestamp: "2026-01-24"},
		{ID: "doc2", Title: "Sample Document 2", Content: "Content of doc 2", Owner: "Admin", Timestamp: "2026-01-24"},
	}

	for _, doc := range docs {
		docJSON, err := json.Marshal(doc)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(doc.ID, docJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state: %v", err)
		}
	}
	return nil
}

// CreateDoc creates a new document (WRITE operation - AdminOrg only)
func (s *SmartContract) CreateDoc(ctx contractapi.TransactionContextInterface, id string, title string, content string, owner string, timestamp string) error {
	exists, err := s.DocExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("document %s already exists", id)
	}

	doc := Document{
		ID:        id,
		Title:     title,
		Content:   content,
		Owner:     owner,
		Timestamp: timestamp,
	}
	docJSON, err := json.Marshal(doc)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, docJSON)
}

// ReadDoc returns a document by ID (QUERY operation - All orgs)
func (s *SmartContract) ReadDoc(ctx contractapi.TransactionContextInterface, id string) (*Document, error) {
	docJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if docJSON == nil {
		return nil, fmt.Errorf("document %s does not exist", id)
	}

	var doc Document
	err = json.Unmarshal(docJSON, &doc)
	if err != nil {
		return nil, err
	}
	return &doc, nil
}

// UpdateDoc updates an existing document (WRITE operation - AdminOrg only)
func (s *SmartContract) UpdateDoc(ctx contractapi.TransactionContextInterface, id string, title string, content string, owner string, timestamp string) error {
	exists, err := s.DocExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("document %s does not exist", id)
	}

	doc := Document{
		ID:        id,
		Title:     title,
		Content:   content,
		Owner:     owner,
		Timestamp: timestamp,
	}
	docJSON, err := json.Marshal(doc)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, docJSON)
}

// DeleteDoc removes a document (WRITE operation - AdminOrg only)
func (s *SmartContract) DeleteDoc(ctx contractapi.TransactionContextInterface, id string) error {
	exists, err := s.DocExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("document %s does not exist", id)
	}
	return ctx.GetStub().DelState(id)
}

// DocExists checks if a document exists
func (s *SmartContract) DocExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	docJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}
	return docJSON != nil, nil
}

// GetAllDocs returns all documents (QUERY operation - All orgs)
func (s *SmartContract) GetAllDocs(ctx contractapi.TransactionContextInterface) ([]*Document, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var docs []*Document
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var doc Document
		err = json.Unmarshal(queryResponse.Value, &doc)
		if err != nil {
			return nil, err
		}
		docs = append(docs, &doc)
	}
	return docs, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating docube-test chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error starting docube-test chaincode: %v", err)
	}
}
