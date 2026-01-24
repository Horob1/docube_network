# Smart Contract (Chaincode) Source

Mã nguồn Smart Contract viết bằng Go, xử lý logic nghiệp vụ lưu trữ tài liệu.

```go
/*
 * Docube Test Chaincode
 */

package main

import (
    "encoding/json"
    "fmt"
    "github.com/hyperledger/fabric-contract-api-go/v2/contractapi"
)

// Cấu trúc dữ liệu Document
type Document struct {
    ID        string `json:"ID"`
    Title     string `json:"Title"`
    Content   string `json:"Content"`
    Owner     string `json:"Owner"`
    Timestamp string `json:"Timestamp"`
}

// Hàm khởi tạo dữ liệu mẫu (InitLedger)
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
    // Tạo sẵn 2 documents mẫu...
}

// Hàm CreateDoc: Tạo document mới
// Logic: Kiểm tra ID tồn tại chưa -> Ghi vào Ledger (PutState)
func (s *SmartContract) CreateDoc(ctx contractapi.TransactionContextInterface, id string, ...) error {
    // ...
    return ctx.GetStub().PutState(id, docJSON)
}

// Hàm ReadDoc: Đọc document theo ID
// Logic: Đọc từ Ledger (GetState) -> Trả về JSON
func (s *SmartContract) ReadDoc(ctx contractapi.TransactionContextInterface, id string) (*Document, error) {
    docJSON, err := ctx.GetStub().GetState(id)
    // ...
}

// Hàm GetAllDocs: Lấy tất cả document
// Logic: GetStateByRange("", "") -> Lặp qua iterator và trả về mảng
func (s *SmartContract) GetAllDocs(ctx contractapi.TransactionContextInterface) ([]*Document, error) {
    resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
    // ...
}

// Hàm Main: Entry point của chaincode
func main() {
    chaincode, err := contractapi.NewChaincode(&SmartContract{})
    chaincode.Start()
}
```
