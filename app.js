import express from 'express';
import matchRoutes from './routes/matches.routes.js';

const app = express();

app.use(express.json());
app.use('/matches', matchRoutes);

app.get('/', (req, res) => {
  res.send('🚀 Cricket API running');
});

export default app;