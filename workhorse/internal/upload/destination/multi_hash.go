package destination

import (
	"crypto/md5"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/hex"
	"hash"
	"io"

	"gitlab.com/gitlab-org/labkit/fips"
)

var hashFactories = map[string](func() hash.Hash){
	"md5":    md5.New,
	"sha1":   sha1.New,
	"sha256": sha256.New,
	"sha512": sha512.New,
}

var fipsHashFactories = map[string](func() hash.Hash){
	"sha1":   sha1.New,
	"sha256": sha256.New,
	"sha512": sha512.New,
}

func factories() map[string](func() hash.Hash) {
	if fips.Enabled() {
		return fipsHashFactories
	}

	return hashFactories
}

type multiHash struct {
	io.Writer
	hashes map[string]hash.Hash
}

func newMultiHash() (m *multiHash) {
	m = &multiHash{}
	m.hashes = make(map[string]hash.Hash)

	var writers []io.Writer
	for hash, hashFactory := range factories() {
		writer := hashFactory()

		m.hashes[hash] = writer
		writers = append(writers, writer)
	}

	m.Writer = io.MultiWriter(writers...)
	return m
}

func (m *multiHash) finish() map[string]string {
	h := make(map[string]string)
	for hashName, hash := range m.hashes {
		checksum := hash.Sum(nil)
		h[hashName] = hex.EncodeToString(checksum)
	}
	return h
}
