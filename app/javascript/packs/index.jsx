import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter as Router, Route } from 'react-router-dom'
import App from '../src/components/App'

document.addEventListener('DOMContentLoaded', () => {
  createRoot(document.body.appendChild(document.createElement('div'))).render(
    <Router>
      <Route path="/" component={App}/>
    </Router>,
  )
})
