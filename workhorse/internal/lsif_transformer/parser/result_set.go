package parser

import (
	"encoding/json"
)

type ResultSet struct {
	Hovers    *Hovers
	RefsCache *cache
}

type RawResultSetRef struct {
	ResultSetId Id `json:"outV"`
	RefId       Id `json:"inV"`
}

func NewResultSet() (*ResultSet, error) {
	hovers, err := NewHovers()
	if err != nil {
		return nil, err
	}

	refsCache, err := newCache("results-set-refs", Id(0))
	if err != nil {
		return nil, err
	}

	return &ResultSet{
		Hovers:    hovers,
		RefsCache: refsCache,
	}, nil
}

func (r *ResultSet) Read(label string, line []byte) error {
	switch label {
	case "textDocument/references":
		if err := r.addResultSetRef(line); err != nil {
			return err
		}
	default:
		return r.Hovers.Read(label, line)
	}

	return nil
}

func (r *ResultSet) HoverFor(refId Id) json.RawMessage {
	var resultSetId Id
	if err := r.RefsCache.Entry(refId, &resultSetId); err != nil {
		return nil
	}

	return r.Hovers.For(resultSetId)
}

func (r *ResultSet) Close() error {
	for _, err := range []error{
		r.RefsCache.Close(),
		r.Hovers.Close(),
	} {
		if err != nil {
			return err
		}
	}
	return nil
}

func (r *ResultSet) addResultSetRef(line []byte) error {
	var ref RawResultSetRef
	if err := json.Unmarshal(line, &ref); err != nil {
		return err
	}

	return r.RefsCache.SetEntry(ref.RefId, ref.ResultSetId)
}
