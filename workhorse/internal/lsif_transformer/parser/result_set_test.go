package parser

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestResultSetRead(t *testing.T) {
	r := setupResultSet(t)

	var id Id
	require.NoError(t, r.RefsCache.Entry(2, &id))
	require.Equal(t, Id(1), id)

	require.NoError(t, r.Close())
}

func setupResultSet(t *testing.T) *ResultSet {
	r, err := NewResultSet()
	require.NoError(t, err)

	require.NoError(t, r.Read("textDocument/references", []byte(`{"id":4,"label":"textDocument/references","outV":"1","inV":2}`)))

	return r
}
