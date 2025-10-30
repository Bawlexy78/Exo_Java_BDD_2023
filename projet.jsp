<%@ page import="java.util.*, java.text.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // ===== Classe interne représentant une tâche =====
    class Task {
        private String title;
        private String description;
        private String dueDate;
        private boolean done;

        public Task(String title, String description, String dueDate) {
            this.title = title;
            this.description = description;
            this.dueDate = dueDate;
            this.done = false;
        }

        public String getTitle() { return title; }
        public String getDescription() { return description; }
        public String getDueDate() { return dueDate; }
        public boolean isDone() { return done; }
        public void setDone(boolean done) { this.done = done; }
    }

    // ===== Récupération de la liste des tâches en session =====
    HttpSession sess = request.getSession();
    List<Task> tasks = (List<Task>) sess.getAttribute("tasks");
    if (tasks == null) {
        tasks = new ArrayList<Task>();
        sess.setAttribute("tasks", tasks);
    }

    // ===== Traitement des actions =====
    String action = request.getParameter("action");
    if ("add".equals(action)) {
        String title = request.getParameter("title");
        String desc = request.getParameter("desc");
        String dueDate = request.getParameter("dueDate");
        if (title != null && !title.trim().isEmpty()) {
            tasks.add(new Task(title, desc, dueDate));
        }
    } else if ("delete".equals(action)) {
        int index = Integer.parseInt(request.getParameter("index"));
        if (index >= 0 && index < tasks.size()) {
            tasks.remove(index);
        }
    } else if ("done".equals(action)) {
        int index = Integer.parseInt(request.getParameter("index"));
        if (index >= 0 && index < tasks.size()) {
            tasks.get(index).setDone(true);
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mini Gestionnaire de Tâches</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        form { margin-bottom: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        th { background: #f0f0f0; }
        .done { text-decoration: line-through; color: gray; }
        .actions form { display:inline; }
    </style>
</head>
<body>
    <h1>Mini Gestionnaire de Tâches</h1>

    <!-- Formulaire d'ajout -->
    <form method="post">
        <input type="hidden" name="action" value="add"/>
        <label>Titre : <input type="text" name="title" required/></label><br/>
        <label>Description : <input type="text" name="desc"/></label><br/>
        <label>Date d'échéance : <input type="date" name="dueDate"/></label><br/>
        <button type="submit">Ajouter la tâche</button>
    </form>

    <!-- Affichage des tâches -->
    <h2>Liste des tâches</h2>
    <table>
        <tr>
            <th>Titre</th>
            <th>Description</th>
            <th>Date d'échéance</th>
            <th>Statut</th>
            <th>Actions</th>
        </tr>
        <%
            for (int i = 0; i < tasks.size(); i++) {
                Task t = tasks.get(i);
        %>
        <tr>
            <td class="<%= t.isDone() ? "done" : "" %>"><%= t.getTitle() %></td>
            <td class="<%= t.isDone() ? "done" : "" %>"><%= t.getDescription() %></td>
            <td class="<%= t.isDone() ? "done" : "" %>"><%= t.getDueDate() %></td>
            <td><%= t.isDone() ? "Terminée" : "En cours" %></td>
            <td class="actions">
                <% if (!t.isDone()) { %>
                <form method="post" style="display:inline">
                    <input type="hidden" name="action" value="done"/>
                    <input type="hidden" name="index" value="<%= i %>"/>
                    <button type="submit">Marquer terminée</button>
                </form>
                <% } %>
                <form method="post" style="display:inline">
                    <input type="hidden" name="action" value="delete"/>
                    <input type="hidden" name="index" value="<%= i %>"/>
                    <button type="submit">Supprimer</button>
                </form>
            </td>
        </tr>
        <% } %>
    </table>
</body>
</html>
